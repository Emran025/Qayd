import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/backup/restore_cubit.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_error_banner.dart';
import 'package:qayd/presentation/components/auth/auth_field.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/components/auth/password_toggle_icon.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/auth/password_reset_page.dart';
import 'package:qayd/presentation/pages/auth/register_page.dart';
import 'package:qayd/presentation/pages/backup/restore_discovery_page.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// First-run provisioning screen shown when [LicenseStatus.pending].
///
/// On success [SecurityCubit] emits a new state that drives the home widget
/// swap in `main.dart` automatically — no manual navigation required.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/auth/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorAr;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorAr = null;
    });

    final result = await context.read<SecurityCubit>().provisionDevice(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (result.success) {
      // Provisioning success — now check for backups before BLoC emission swaps the UI.
      // NOTE: SecurityCubit emits the new state at the end of provisionDevice,
      // but Flutter's build cycle happens after the current task.

      final restoreCubit = InjectionContainer.restoreCubit;
      await restoreCubit.checkBackups();

      if (restoreCubit.state is RestoreFound && mounted) {
        final restored = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: restoreCubit,
              child: const RestoreDiscoveryPage(),
            ),
          ),
        );

        if (restored == true) {
          // Re-open DB with restored file
          await InjectionContainer.reopenDatabaseAfterRestore();
        }
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.success) setState(() => _errorAr = result.errorAr);
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.lg,
              vertical: SpacingTokens.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  const AuthAnimatedIcon(
                    iconData: Icons.shield_rounded,
                    iconColor: ColorTokens.emerald500,
                  ),
                  const SizedBox(height: SpacingTokens.lg),

                  // Title
                  AuthTitleBlock(
                    title: AppStringsAr.loginTitle,
                    subtitle: AppStringsAr.loginSubtitle,
                  ),
                  const SizedBox(height: SpacingTokens.xl),

                  // Email
                  AuthField(
                    controller: _emailCtrl,
                    hint: AppStringsAr.vaultEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStringsAr.activationFieldRequired;
                      }
                      if (!v.contains('@')) return AppStringsAr.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacingTokens.sm),

                  // Password
                  AuthField(
                    controller: _passwordCtrl,
                    hint: AppStringsAr.vaultPasswordHint,
                    obscureText: _obscurePassword,
                    suffixIcon: PasswordToggleIcon(
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStringsAr.activationFieldRequired
                        : null,
                  ),

                  // Error
                  if (_errorAr != null) ...[
                    const SizedBox(height: SpacingTokens.sm),
                    AuthErrorBanner(message: _errorAr!),
                  ],
                  const SizedBox(height: SpacingTokens.md),

                  // Submit
                  AuthSubmitButton(
                    label: AppStringsAr.loginAction,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: SpacingTokens.md),

                  // Forgot password
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PasswordResetPage()),
                    ),
                    child: Text(
                      AppStringsAr.forgotPassword,
                      style: const TextStyle(
                          color: ColorTokens.emerald400, fontSize: 13),
                    ),
                  ),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStringsAr.noAccount,
                        style: const TextStyle(
                            color: ColorTokens.slate400, fontSize: 13),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        ),
                        child: Text(
                          AppStringsAr.createAccount,
                          style: const TextStyle(
                            color: ColorTokens.emerald400,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
