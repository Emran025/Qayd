import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qayd/core/constants/app_constants.dart';
import 'package:qayd/data/security/app_pin_storage.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/governance/governance_host_page.dart';
import 'package:qayd/presentation/security/app_lock_screen.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/security/security_lifecycle_observer.dart';
import 'package:qayd/presentation/security/security_state.dart';
import 'package:qayd/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.init();
  final pinStorage = AppPinStorage();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final c = SecurityCubit(pinStorage: pinStorage);
            Future<void>.microtask(() => c.refreshPreferences());
            return c;
          },
        ),
        BlocProvider(
          create: (_) => GovernanceCubit(
            InjectionContainer.checkGovernanceStatusUseCase,
            InjectionContainer.submitActivationUseCase,
          )..scheduleBackgroundVerification(),
        ),
      ],
      child: SecurityLifecycleObserver(
        child: const QaydApp(),
      ),
    ),
  );
}

class QaydApp extends StatelessWidget {
  const QaydApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Locale(AppConstants.defaultLanguageCode);
    return MaterialApp(
      title: AppStringsAr.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              BlocBuilder<SecurityCubit, SecurityState>(
                builder: (context, sec) {
                  if (!sec.isLocked) return const SizedBox.shrink();
                  return const Positioned.fill(
                    child: AppLockScreen(),
                  );
                },
              ),
            ],
          ),
        );
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: ValueListenableBuilder<int>(
        valueListenable: InjectionContainer.databaseEpoch,
        builder: (context, gen, _) {
          return GovernanceHostPage(key: ValueKey<int>(gen));
        },
      ),
    );
  }
}
