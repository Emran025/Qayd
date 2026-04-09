import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qayd/core/constants/app_constants.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/sync/sync_status_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/auth/login_page.dart';
import 'package:qayd/presentation/pages/governance/governance_host_page.dart';
import 'package:qayd/presentation/security/app_lock_screen.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/security/security_lifecycle_observer.dart';
import 'package:qayd/presentation/security/security_lock_overlay.dart';
import 'package:qayd/presentation/security/security_state.dart';
import 'package:qayd/presentation/theme/app_theme.dart';
import 'package:qayd/presentation/utils/no_stretch_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SecurityCubit>(
          create: (_) {
            final c = InjectionContainer.securityCubit;
            Future<void>.microtask(() => c.bootCheck());
            return c;
          },
        ),
        BlocProvider<GovernanceCubit>(
          create: (_) => GovernanceCubit(
            InjectionContainer.checkGovernanceStatusUseCase,
            InjectionContainer.submitActivationUseCase,
          )..scheduleBackgroundVerification(),
        ),
        BlocProvider<SyncStatusCubit>(
          create: (_) => InjectionContainer.syncStatusCubit,
        ),
      ],
      child: const SecurityLifecycleObserver(child: QaydApp()),
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
      scrollBehavior: const NoStretchScrollBehavior(),
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
          // SecurityLockOverlay handles hard-blocks (license, clock tamper).
          // AppLockScreen handles PIN lock.
          child: SecurityLockOverlay(
            child: Stack(
              fit: StackFit.expand,
              children: [
                child ?? const SizedBox.shrink(),
                BlocBuilder<SecurityCubit, SecurityState>(
                  builder: (context, sec) {
                    if (!sec.isLocked) return const SizedBox.shrink();
                    return const Positioned.fill(child: AppLockScreen());
                  },
                ),
              ],
            ),
          ),
        );
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: BlocBuilder<SecurityCubit, SecurityState>(
        buildWhen: (prev, next) => prev.licenseStatus != next.licenseStatus,
        builder: (context, state) {
          if (state.licenseStatus == LicenseStatus.pending) {
            return const LoginPage();
          }
          return ValueListenableBuilder<int>(
            valueListenable: InjectionContainer.databaseEpoch,
            builder: (context, gen, _) =>
                GovernanceHostPage(key: ValueKey<int>(gen)),
          );
        },
      ),
    );
  }
}
