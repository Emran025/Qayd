import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_error_banner.dart';
import 'package:qayd/presentation/components/auth/auth_field.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/components/auth/password_toggle_icon.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/auth/email_verification_otp_page.dart';
import 'package:qayd/presentation/pages/auth/password_reset_page.dart';
import 'package:qayd/presentation/pages/auth/register_page.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/sync/companion_link_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/di/injection_container.dart';

/// First-run provisioning screen shown when [LicenseStatus.pending].
///
/// On success [SecurityCubit] emits a new state that drives the home widget
/// swap in `main.dart` automatically — no manual navigation required.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onProvisioningComplete});

  /// Called after successful provisioning to trigger database initialization.
  final Future<void> Function()? onProvisioningComplete;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingBanner());
  }

  Future<void> _consumePendingBanner() async {
    final msg =
        await InjectionContainer.licenseVault.readAndClearPendingAuthBannerAr();
    if (msg != null && mounted) {
      setState(() => _errorAr = msg);
    }
  }

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

    if (result.success && result.emailUnverified) {
      // Redirect to OTP page
      final otpSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EmailVerificationOtpPage(email: _emailCtrl.text.trim()),
        ),
      );

      if (otpSuccess != true) {
        setState(() => _loading = false);
        return;
      }
      // If verified successfully, fall through to complete provisioning!
    }

    if (result.success) {
      // Notify parent to open database now that provisioning is done.
      if (widget.onProvisioningComplete != null) {
        await widget.onProvisioningComplete!();
      } else {
        // If onProvisioningComplete is null, we are rendering LoginPage from within
        // QaydApp (after a logout). We need to reopen the database manually here.
        await InjectionContainer.reopenDatabaseAfterRestore();

        // We must sync identity manually since SecurityCubit skipped it because DB wasn't ready.
        InjectionContainer.syncIdentityToInternalAccountsUseCase
            .call()
            .ignore();
      }

      if (!mounted) return;
      setState(() => _loading = false);
      return;
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
                  SizedBox(height: SpacingTokens.lg),

                  // Title
                  AuthTitleBlock(
                    title: AppStrings.loginTitle,
                    subtitle: AppStrings.loginSubtitle,
                  ),
                  SizedBox(height: SpacingTokens.xl),

                  // Email
                  AuthField(
                    controller: _emailCtrl,
                    hint: AppStrings.vaultEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.activationFieldRequired;
                      }
                      if (!v.contains('@')) return AppStrings.invalidEmail;
                      return null;
                    },
                  ),
                  SizedBox(height: SpacingTokens.sm),

                  // Password
                  AuthField(
                    controller: _passwordCtrl,
                    hint: AppStrings.vaultPasswordHint,
                    obscureText: _obscurePassword,
                    isPassword: true,
                    suffixIcon: PasswordToggleIcon(
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.activationFieldRequired
                        : null,
                  ),

                  // Error
                  if (_errorAr != null) ...[
                    SizedBox(height: SpacingTokens.sm),
                    AuthErrorBanner(message: _errorAr!),
                  ],
                  SizedBox(height: SpacingTokens.md),

                  // Submit
                  AuthSubmitButton(
                    label: AppStrings.loginAction,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  SizedBox(height: SpacingTokens.md),

                  // Forgot password
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PasswordResetPage()),
                    ),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: const TextStyle(
                          color: ColorTokens.emerald400, fontSize: 13),
                    ),
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompanionLinkPage(
                                  onProvisioningComplete: () async {
                                    if (widget.onProvisioningComplete != null) {
                                      await widget.onProvisioningComplete!();
                                    } else {
                                      await InjectionContainer
                                          .reopenDatabaseAfterRestore();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                    child: Text(AppStrings.linkAsCompanionDevice),
                  ),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.noAccount,
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
                          AppStrings.createAccount,
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
