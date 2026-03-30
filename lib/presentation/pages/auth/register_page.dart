import 'package:flutter/material.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/auth/auth_admin_badge.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_error_banner.dart';
import 'package:qayd/presentation/components/auth/auth_field.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/components/auth/password_toggle_icon.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Admin-only account provisioning screen.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const routeName = '/auth/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorAr;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorAr = null;
    });

    try {
      final hardwareId =
          await InjectionContainer.hardwareIdService.obtainHardwareId();

      final result = await InjectionContainer.authRepository.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        deviceId: hardwareId,
      );

      await InjectionContainer.licenseVault.writeJwt(result.jwt);
      await InjectionContainer.licenseVault
          .writeLicenseData(result.licenseData);
      await InjectionContainer.licenseVault
          .writeProvisionedHardwareId(hardwareId);
      if (result.serverSalt.isNotEmpty) {
        await InjectionContainer.licenseVault
            .writeServerSalt(result.serverSalt);
      }
      await InjectionContainer.licenseVault
          .writeTrialStart(DateTime.now().toUtc());

      if (!mounted) return;
      await InjectionContainer.securityCubit.bootCheck();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      setState(() => _errorAr = e.messageAr);
    } catch (_) {
      setState(
          () => _errorAr = 'تعذر الاتصال بالخادم. تحقق من الاتصال وحاول مجدداً.');
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
            // Back button
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: ColorTokens.slate400, size: 20),
                tooltip: AppStringsAr.backToLogin,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Icon + badge
                      const AuthAnimatedIcon(
                        iconData: Icons.admin_panel_settings_rounded,
                        iconColor: ColorTokens.goldAccent,
                        pulseDuration: Duration(milliseconds: 2200),
                      ),
                      const SizedBox(height: SpacingTokens.md),
                      AuthTitleBlock(
                        title: AppStringsAr.registerTitle,
                        subtitle: '',
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      AuthAdminBadge(label: AppStringsAr.registerSubtitle),
                      const SizedBox(height: SpacingTokens.lg),

                      // Fields
                      AuthField(
                        controller: _nameCtrl,
                        hint: AppStringsAr.nameHint,
                        keyboardType: TextInputType.name,
                        accentColor: ColorTokens.goldAccent,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppStringsAr.activationFieldRequired
                            : null,
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      AuthField(
                        controller: _emailCtrl,
                        hint: AppStringsAr.vaultEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        accentColor: ColorTokens.goldAccent,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return AppStringsAr.activationFieldRequired;
                          }
                          if (!v.contains('@')) return AppStringsAr.invalidEmail;
                          return null;
                        },
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      AuthField(
                        controller: _passwordCtrl,
                        hint: AppStringsAr.vaultPasswordHint,
                        obscureText: _obscurePassword,
                        accentColor: ColorTokens.goldAccent,
                        suffixIcon: PasswordToggleIcon(
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return AppStringsAr.activationFieldRequired;
                          }
                          if (v.length < 8) {
                            return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      AuthField(
                        controller: _confirmCtrl,
                        hint: AppStringsAr.confirmPasswordHint,
                        obscureText: _obscureConfirm,
                        accentColor: ColorTokens.goldAccent,
                        suffixIcon: PasswordToggleIcon(
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) => (v != _passwordCtrl.text)
                            ? AppStringsAr.passwordMismatch
                            : null,
                      ),

                      // Error
                      if (_errorAr != null) ...[
                        const SizedBox(height: SpacingTokens.sm),
                        AuthErrorBanner(message: _errorAr!),
                      ],
                      const SizedBox(height: SpacingTokens.lg),

                      // Submit
                      AuthSubmitButton(
                        label: AppStringsAr.registerAction,
                        color: ColorTokens.goldAccent,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: SpacingTokens.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
