import 'package:flutter/material.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_error_banner.dart';
import 'package:qayd/presentation/components/auth/auth_field.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/components/auth/password_toggle_icon.dart';
import 'package:qayd/presentation/components/auth/step_progress_dot.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Two-step password recovery flow.
///
/// Step 0 — Email input → [requestPasswordReset].
/// Step 1 — OTP token + new password → [confirmPasswordReset].
class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  static const routeName = '/auth/password-reset';

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();

  int _step = 0;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorAr;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (_loading) return;
    if (!(_step0Key.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorAr = null;
    });
    try {
      await InjectionContainer.authRepository
          .requestPasswordReset(email: _emailCtrl.text.trim());
      if (mounted) setState(() => _step = 1);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorAr = e.messageAr);
    } catch (_) {
      if (mounted) {
        setState(() => _errorAr = AppStringsAr.passwordResetError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (_loading) return;
    if (!(_step1Key.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorAr = null;
    });
    try {
      await InjectionContainer.authRepository.confirmPasswordReset(
        email: _emailCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
        newPassword: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStringsAr.passwordResetSuccess),
          backgroundColor: ColorTokens.emerald700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorAr = e.messageAr);
    } catch (_) {
      if (mounted) {
        setState(() => _errorAr = AppStringsAr.passwordChangeError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: ColorTokens.slate400, size: 20),
                    tooltip: AppStringsAr.backToLogin,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Row(children: [
                    StepProgressDot(active: _step == 0),
                    const SizedBox(width: 6),
                    StepProgressDot(active: _step == 1),
                  ]),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
                child: Column(
                  children: [
                    const SizedBox(height: SpacingTokens.md),

                    // Icon — animates between states
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _step == 0
                          ? const AuthAnimatedIcon(
                              key: ValueKey('icon_0'),
                              iconData: Icons.lock_reset_rounded,
                              iconColor: ColorTokens.emerald500,
                            )
                          : const AuthAnimatedIcon(
                              key: ValueKey('icon_1'),
                              iconData: Icons.verified_rounded,
                              iconColor: ColorTokens.goldAccent,
                              pulseDuration: Duration(milliseconds: 2200),
                            ),
                    ),
                    const SizedBox(height: SpacingTokens.md),

                    // Title + subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AuthTitleBlock(
                        key: ValueKey<int>(_step),
                        title: AppStringsAr.passwordResetTitle,
                        subtitle: _step == 0
                            ? AppStringsAr.passwordResetSubtitle
                            : AppStringsAr.passwordResetEmailSent,
                        subtitleColor:
                            _step == 1 ? ColorTokens.emerald400 : null,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.lg),

                    // Step forms
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _step == 0
                          ? _Step0Form(
                              key: const ValueKey('form_0'),
                              formKey: _step0Key,
                              emailCtrl: _emailCtrl,
                              loading: _loading,
                              errorAr: _errorAr,
                              onSubmit: _sendLink,
                            )
                          : _Step1Form(
                              key: const ValueKey('form_1'),
                              formKey: _step1Key,
                              tokenCtrl: _tokenCtrl,
                              passwordCtrl: _passwordCtrl,
                              confirmCtrl: _confirmCtrl,
                              loading: _loading,
                              errorAr: _errorAr,
                              obscurePassword: _obscurePassword,
                              obscureConfirm: _obscureConfirm,
                              onTogglePassword: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              onToggleConfirm: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              onSubmit: _confirmReset,
                            ),
                    ),
                    const SizedBox(height: SpacingTokens.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 0 — email ───────────────────────────────────────────────────────────

class _Step0Form extends StatelessWidget {
  const _Step0Form({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.errorAr,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final String? errorAr;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(children: [
        // Method Selector Unit
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              _buildMethodOption(
                icon: Icons.alternate_email_rounded,
                title: AppStringsAr.verificationMethodEmailTitle,
                subtitle: AppStringsAr.verificationMethodEmailSubtitle,
                selected: true,
                onTap: () {},
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white10, height: 1),
              ),
              _buildMethodOption(
                icon: Icons.sms_rounded,
                title: AppStringsAr.verificationMethodPhoneTitle,
                subtitle: AppStringsAr.verificationMethodPhoneSubtitle,
                selected: false,
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),

        AuthField(
          controller: emailCtrl,
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
        if (errorAr != null) ...[
          const SizedBox(height: SpacingTokens.sm),
          AuthErrorBanner(message: errorAr!),
        ],
        const SizedBox(height: SpacingTokens.md),
        AuthSubmitButton(
          label: AppStringsAr.passwordResetAction,
          loading: loading,
          onPressed: onSubmit,
        ),
      ]),
    );
  }

  Widget _buildMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? ColorTokens.emerald500.withOpacity(0.15)
                    : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color:
                      selected ? ColorTokens.emerald500 : ColorTokens.slate400,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? Colors.white : ColorTokens.slate400,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: ColorTokens.slate400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: ColorTokens.emerald500, size: 24),
            if (!enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(AppStringsAr.comingSoonBadge,
                    style:
                        TextStyle(color: ColorTokens.slate400, fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1 — token + new password ────────────────────────────────────────────

class _Step1Form extends StatelessWidget {
  const _Step1Form({
    super.key,
    required this.formKey,
    required this.tokenCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.loading,
    required this.errorAr,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController tokenCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool loading;
  final String? errorAr;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(children: [
        AuthField(
          controller: tokenCtrl,
          hint: AppStringsAr.passwordResetTokenHint,
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? AppStringsAr.activationFieldRequired
              : null,
        ),
        const SizedBox(height: SpacingTokens.sm),
        AuthField(
          controller: passwordCtrl,
          hint: AppStringsAr.passwordResetNewPassword,
          obscureText: obscurePassword,
          suffixIcon: PasswordToggleIcon(
              obscure: obscurePassword, onToggle: onTogglePassword),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return AppStringsAr.activationFieldRequired;
            }
            if (v.length < 8) {
              return AppStringsAr.passwordTooShort;
            }
            return null;
          },
        ),
        const SizedBox(height: SpacingTokens.sm),
        AuthField(
          controller: confirmCtrl,
          hint: AppStringsAr.confirmPasswordHint,
          obscureText: obscureConfirm,
          suffixIcon: PasswordToggleIcon(
              obscure: obscureConfirm, onToggle: onToggleConfirm),
          validator: (v) =>
              (v != passwordCtrl.text) ? AppStringsAr.passwordMismatch : null,
        ),
        if (errorAr != null) ...[
          const SizedBox(height: SpacingTokens.sm),
          AuthErrorBanner(message: errorAr!),
        ],
        const SizedBox(height: SpacingTokens.md),
        AuthSubmitButton(
          label: AppStringsAr.passwordResetConfirmAction,
          color: ColorTokens.goldAccent,
          loading: loading,
          onPressed: onSubmit,
        ),
      ]),
    );
  }
}
