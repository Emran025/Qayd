import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qayd/core/constants/app_constants.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/sync/sync_status_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/auth/database_recovery_page.dart';
import 'package:qayd/presentation/pages/auth/login_page.dart';
import 'package:qayd/presentation/pages/governance/governance_host_page.dart';
import 'package:qayd/presentation/pages/auth/post_auth_gate_page.dart';
import 'package:qayd/presentation/security/app_lock_screen.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/security/security_lifecycle_observer.dart';
import 'package:qayd/presentation/security/security_lock_overlay.dart';
import 'package:qayd/presentation/security/security_state.dart';
import 'package:qayd/presentation/theme/app_theme.dart';
import 'package:qayd/presentation/utils/no_stretch_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phase A: only lightweight services (no database).
  await InjectionContainer.initPreAuth();

  runApp(const QaydAppBootstrapper());
}

// ═══════════════════════════════════════════════════════════════════════════════
// QaydAppBootstrapper — Two-phase initialisation coordinator
// ═══════════════════════════════════════════════════════════════════════════════

/// Top-level widget that handles the two-phase initialization:
///   1. Pre-auth: show login screen if not provisioned.
///   2. Post-auth: open database, then hand off to [QaydApp].
class QaydAppBootstrapper extends StatefulWidget {
  const QaydAppBootstrapper({super.key});

  @override
  State<QaydAppBootstrapper> createState() => _QaydAppBootstrapperState();
}

class _QaydAppBootstrapperState extends State<QaydAppBootstrapper> {
  bool _databaseReady = false;
  bool _keyMismatch = false;
  bool _initializingDb = false;
  String? _dbErrorMessage;

  @override
  void initState() {
    super.initState();
    _checkAndInitDatabase();
  }

  // ── Database lifecycle ──────────────────────────────────────────────────────

  Future<void> _checkAndInitDatabase() async {
    final provisioned = await InjectionContainer.licenseVault.isProvisioned();
    if (provisioned) await _openDatabase();
  }

  Future<void> _onProvisioningComplete() async => _openDatabase();

  Future<void> _openDatabase() async {
    if (_initializingDb) return;
    setState(() {
      _initializingDb = true;
      _keyMismatch = false;
      _dbErrorMessage = null;
    });

    final result = await InjectionContainer.initDatabase();
    if (!mounted) return;

    switch (result) {
      case DatabaseOpenResult.success:
      case DatabaseOpenResult.freshCreated:
        setState(() {
          _databaseReady = true;
          _initializingDb = false;
        });
        Future<void>.microtask(
            () => InjectionContainer.securityCubit.bootCheck());
        break;

      case DatabaseOpenResult.keyMismatch:
        setState(() {
          _keyMismatch = true;
          _initializingDb = false;
          _dbErrorMessage = AppStringsAr.dbKeyMismatchBody;
        });
        break;

      case DatabaseOpenResult.otherError:
        setState(() {
          _initializingDb = false;
          _dbErrorMessage = AppStringsAr.dbOpenErrorBody;
        });
        break;
    }
  }

  Future<void> _retryWithMnemonic(String mnemonic) async {
    setState(() {
      _initializingDb = true;
      _keyMismatch = false;
      _dbErrorMessage = null;
    });

    final ok = await InjectionContainer.retryDatabaseWithMnemonic(mnemonic);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _databaseReady = true;
        _initializingDb = false;
      });
      Future<void>.microtask(
          () => InjectionContainer.securityCubit.bootCheck());
    } else {
      setState(() {
        _keyMismatch = true;
        _initializingDb = false;
        _dbErrorMessage = AppStringsAr.dbKeyMismatchRetryFailed;
      });
    }
  }

  Future<void> _startFresh() async {
    setState(() {
      _initializingDb = true;
      _keyMismatch = false;
      _dbErrorMessage = null;
    });

    final result = await InjectionContainer.resetDatabaseAndInit();
    if (!mounted) return;

    if (result == DatabaseOpenResult.success ||
        result == DatabaseOpenResult.freshCreated) {
      setState(() {
        _databaseReady = true;
        _initializingDb = false;
      });
      Future<void>.microtask(
          () => InjectionContainer.securityCubit.bootCheck());
    } else {
      setState(() {
        _initializingDb = false;
        _dbErrorMessage = AppStringsAr.dbOpenErrorBody;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<SecurityCubit, SecurityState>(
      bloc: InjectionContainer.securityCubit,
      listenWhen: (prev, next) => prev.licenseStatus != next.licenseStatus,
      listener: (context, state) {
        if (state.licenseStatus == LicenseStatus.pending) {
          if (_databaseReady) {
            setState(() => _databaseReady = false);
          }
        }
      },
      child: !_databaseReady
          ? _buildPreAuthApp()
          : MultiBlocProvider(
              providers: [
                BlocProvider<SecurityCubit>(
                  create: (_) => InjectionContainer.securityCubit,
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

  Widget _buildPreAuthApp() {
    final locale = Locale(AppConstants.defaultLanguageCode);
    return BlocProvider<SecurityCubit>.value(
      value: InjectionContainer.securityCubit,
      child: MaterialApp(
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (context) => _buildPreAuthBody(context)),
        ),
      ),
    );
  }

  Widget _buildPreAuthBody(BuildContext context) {
    if (_initializingDb) return _bootSplash(context);
    if (_keyMismatch) {
      return DatabaseRecoveryPage(
        errorMessage: _dbErrorMessage ?? '',
        onRetryWithMnemonic: _retryWithMnemonic,
        onStartFresh: _startFresh,
        onRetry: _openDatabase,
      );
    }
    if (_dbErrorMessage != null) return _errorScreen(context);
    return LoginPage(onProvisioningComplete: _onProvisioningComplete);
  }

  Widget _bootSplash(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              AppStringsAr.dbOpeningProgress,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorScreen(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                AppStringsAr.dbOpenErrorTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _dbErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openDatabase,
                icon: const Icon(Icons.refresh),
                label: Text(AppStringsAr.dbRetryAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QaydApp — Post-auth MaterialApp (database is open)
// ═══════════════════════════════════════════════════════════════════════════════

class QaydApp extends StatefulWidget {
  const QaydApp({super.key});

  @override
  State<QaydApp> createState() => _QaydAppState();
}

class _QaydAppState extends State<QaydApp> {
  /// Tracks whether the post-auth onboarding gate has been completed.
  /// Once `true`, the user goes directly to [GovernanceHostPage].
  bool _onboardingComplete = false;
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // If the user already has a local identity AND had the app set up,
    // skip the gate entirely. The gate is only for first-time setup
    // or after a fresh login where state needs to be established.
    //
    // NOTE: All discovery (backups, server identity, OTP) is now handled
    // inside PostAuthGatePage._evaluateState() to avoid race conditions.
    final hasIdentity = await InjectionContainer.mnemonicVault.hasIdentity();

    if (hasIdentity) {
      if (mounted) {
        setState(() => _onboardingComplete = true);
      }
    }
  }

  void _onGateComplete() {
    if (mounted) {
      setState(() => _onboardingComplete = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Locale(AppConstants.defaultLanguageCode);
    final theme = Theme.of(context);
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
        return GestureDetector(
          onTap: () {
            // Dismiss focus/keyboard when tapping outside an input field
            FocusManager.instance.primaryFocus?.unfocus();
          },
          // Translucent behavior allows the tap to reach widgets below while still detecting it
          behavior: HitTestBehavior.translucent,
          child: Directionality(
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
          ),
        );
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: BlocConsumer<SecurityCubit, SecurityState>(
        listenWhen: (prev, next) => prev.licenseStatus != next.licenseStatus,
        listener: (context, state) {
          if (state.licenseStatus == LicenseStatus.pending) {
            // When a user logs out, we must reset the onboarding flag so the next
            // user goes through the PostAuthGatePage for identity validation.
            if (mounted) {
              setState(() => _onboardingComplete = false);
            }
          }
        },
        buildWhen: (prev, next) => prev.licenseStatus != next.licenseStatus,
        builder: (context, state) {
          if (state.licenseStatus == LicenseStatus.booting) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 24),
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                  ],
                ),
              ),
            );
          }
          // Note: LicenseStatus.pending is handled by QaydAppBootstrapper unmounting this app.

          // ── Post-Auth Gate ─────────────────────────────────────────────
          // Show the onboarding gate for first-time setup.
          if (!_onboardingComplete) {
            return PostAuthGatePage(
              onSetupComplete: _onGateComplete,
            );
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
