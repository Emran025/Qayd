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
    if (!_databaseReady) return _buildPreAuthApp();

    return MultiBlocProvider(
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
          child: _buildPreAuthBody(),
        ),
      ),
    );
  }

  Widget _buildPreAuthBody() {
    if (_initializingDb) return _bootSplash();
    if (_keyMismatch) {
      return DatabaseRecoveryPage(
        errorMessage: _dbErrorMessage ?? '',
        onRetryWithMnemonic: _retryWithMnemonic,
        onStartFresh: _startFresh,
        onRetry: _openDatabase,
      );
    }
    if (_dbErrorMessage != null) return _errorScreen();
    return LoginPage(onProvisioningComplete: _onProvisioningComplete);
  }

  Widget _bootSplash() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppStringsAr.dbOpeningProgress,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppStringsAr.dbOpenErrorTitle,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _dbErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
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

  /// Whether this is a returning account (server had an existing identity).
  bool _isReturningAccount = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // If the user already has a local identity AND had the app set up,
    // skip the gate entirely. The gate is only for first-time setup
    // or after a fresh login where state needs to be established.
    final hasIdentity = await InjectionContainer.mnemonicVault.hasIdentity();
    final hasPin = await InjectionContainer.securityCubit.hasPinConfigured();

    if (hasIdentity) {
      // User has identity — check if this might be a returning account
      // (e.g., re-login on a different device where identity was restored
      // from the vault file but the user hasn't gone through device lock).
      if (mounted) {
        setState(() => _onboardingComplete = true);
      }
      return;
    }

    // No local identity — check server for existing identity
    try {
      final licenseData =
          await InjectionContainer.licenseVault.readLicenseData();
      final email = licenseData?['email'] as String?;
      if (email != null && email.isNotEmpty) {
        final lookup = await InjectionContainer.identityRepository
            .lookupByEmail(email: email);
        if (mounted) {
          setState(() => _isReturningAccount = lookup != null);
        }
      }
    } catch (_) {
      // Network failure — not critical, default to new account flow.
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
      home: BlocBuilder<SecurityCubit, SecurityState>(
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
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }
          if (state.licenseStatus == LicenseStatus.pending) {
            return const LoginPage();
          }

          // ── Post-Auth Gate ─────────────────────────────────────────────
          // Show the onboarding gate for first-time setup.
          if (!_onboardingComplete) {
            return PostAuthGatePage(
              isReturningAccount: _isReturningAccount,
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
