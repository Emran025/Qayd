import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/app_document.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/components/auth/auth_admin_badge.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_error_banner.dart';
import 'package:qayd/presentation/components/auth/auth_field.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/components/auth/password_toggle_icon.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/inputs/phone_zone.dart';
import 'package:qayd/presentation/pages/auth/email_verification_otp_page.dart';

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
  final _zoneCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  String? _errorAr;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _zoneCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms) {
      setState(() => _errorAr = AppStrings.agreeToTermsRequired);
      return;
    }
    setState(() {
      _loading = true;
      _errorAr = null;
    });

    final result = await context.read<SecurityCubit>().registerDevice(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: (_zoneCtrl.text + _phoneCtrl.text)
              .replaceAll(' ', '')
              .replaceAll('+', ''),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (result.success && result.emailUnverified) {
      // Navigate to OTP verification page
      final otpSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EmailVerificationOtpPage(email: _emailCtrl.text.trim()),
        ),
      );

      if (otpSuccess != true) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      // If verified successfully, we can proceed.
    }

    if (result.success) {
      // Success! The SecurityCubit has already updated the license vault and handled any wipes.
      // We pop back to LoginPage which will handle the onProvisioningComplete if it's the home page,
      // or we can trigger it here if needed.
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _errorAr = result.errorAr;
      });
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
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: ColorTokens.slate400, size: 20),
                tooltip: AppStrings.backToLogin,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
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
                      SizedBox(height: SpacingTokens.md),
                      AuthTitleBlock(
                        title: AppStrings.registerTitle,
                        subtitle: '',
                      ),
                      SizedBox(height: SpacingTokens.sm),
                      AuthAdminBadge(label: AppStrings.registerSubtitle),
                      SizedBox(height: SpacingTokens.lg),

                      // Fields
                      AuthField(
                        controller: _nameCtrl,
                        hint: AppStrings.nameHint,
                        keyboardType: TextInputType.name,
                        accentColor: ColorTokens.goldAccent,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppStrings.activationFieldRequired
                            : null,
                      ),
                      SizedBox(height: SpacingTokens.sm),
                      AuthField(
                        controller: _emailCtrl,
                        hint: AppStrings.vaultEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        accentColor: ColorTokens.goldAccent,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return AppStrings.activationFieldRequired;
                          }
                          if (!v.contains('@')) {
                            return AppStrings.invalidEmail;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SpacingTokens.sm),
                      PhoneZoneForm(
                        zoneController: _zoneCtrl,
                        phoneController: _phoneCtrl,
                        label: AppStrings.partyPhoneLabel,
                      ),
                      SizedBox(height: SpacingTokens.sm),
                      AuthField(
                        controller: _passwordCtrl,
                        hint: AppStrings.vaultPasswordHint,
                        obscureText: _obscurePassword,
                        isPassword: true,
                        accentColor: ColorTokens.goldAccent,
                        suffixIcon: PasswordToggleIcon(
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return AppStrings.activationFieldRequired;
                          }
                          if (v.length < 8) {
                            return AppStrings.passwordTooShort;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SpacingTokens.sm),
                      AuthField(
                        controller: _confirmCtrl,
                        hint: AppStrings.confirmPasswordHint,
                        obscureText: _obscureConfirm,
                        isPassword: true,
                        accentColor: ColorTokens.goldAccent,
                        suffixIcon: PasswordToggleIcon(
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) => (v != _passwordCtrl.text)
                            ? AppStrings.passwordMismatch
                            : null,
                      ),

                      // Terms and Privacy Checkbox
                      SizedBox(height: SpacingTokens.md),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            activeColor: ColorTokens.goldAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) {
                              setState(() => _agreedToTerms = v ?? false);
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsAndPrivacy,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                     TextSpan(
                                        text: AppStrings.iAgreeTo,
                                        style: TextStyle(
                                            color: ColorTokens.slate400,
                                            fontSize: 13)),
                                    TextSpan(
                                        text: AppStrings.termsOfUseLabel,
                                        style:  TextStyle(
                                            color: ColorTokens.goldAccent,
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.underline)),
                                     TextSpan(
                                        text: AppStrings.andLabel,
                                        style: TextStyle(
                                            color: ColorTokens.slate400,
                                            fontSize: 13)),
                                    TextSpan(
                                        text: AppStrings.privacyPolicyLabel,
                                        style: const TextStyle(
                                            color: ColorTokens.goldAccent,
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.underline)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Error
                      if (_errorAr != null) ...[
                        SizedBox(height: SpacingTokens.sm),
                        AuthErrorBanner(message: _errorAr!),
                      ],
                      SizedBox(height: SpacingTokens.lg),

                      // Submit
                      AuthSubmitButton(
                        label: AppStrings.registerAction,
                        color: ColorTokens.goldAccent,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      SizedBox(height: SpacingTokens.xl),
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

  Future<void> _showTermsAndPrivacy() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentBottomSheetDialog(),
    );
  }
}

class _DocumentBottomSheetDialog extends StatefulWidget {
  @override
  State<_DocumentBottomSheetDialog> createState() =>
      _DocumentBottomSheetDialogState();
}

class _DocumentBottomSheetDialogState
    extends State<_DocumentBottomSheetDialog> {
  bool _loading = true;
  List<DocumentClause> _termsClauses = [];
  List<DocumentClause> _privacyClauses = [];
  String _termsFallback = AppStrings.loadingLabel;
  String _privacyFallback = AppStrings.loadingLabel;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final result = await InjectionContainer.appConfigRepository.getDocuments();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _loading = false;
            _termsFallback = AppStrings.termsLoadingError;
            _privacyFallback = AppStrings.privacyLoadingError;
          });
        }
      },
      (docs) {
        if (mounted) {
          setState(() {
            _loading = false;
            final tDoc = docs['terms_of_use'];
            final pDoc = docs['privacy_policy'];

            if (tDoc != null) {
              _termsClauses = tDoc.clauses;
              _termsFallback = tDoc.content.isNotEmpty
                  ? tDoc.content
                  : AppStrings.noTermsFound;
            } else {
              _termsFallback = AppStrings.noTermsFound;
            }

            if (pDoc != null) {
              _privacyClauses = pDoc.clauses;
              _privacyFallback = pDoc.content.isNotEmpty
                  ? pDoc.content
                  : AppStrings.noPrivacyFound;
            } else {
              _privacyFallback = AppStrings.noPrivacyFound;
            }
          });
        }
      },
    );
  }

  Widget _buildClausesSection(
      String sectionTitle, List<DocumentClause> clauses, String fallback) {
    if (clauses.isEmpty && fallback.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: const TextStyle(
            color: ColorTokens.goldAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        if (clauses.isNotEmpty)
          ...clauses.map((clause) => Container(
                margin: const EdgeInsets.only(bottom: SpacingTokens.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // slate800
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(SpacingTokens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clause.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: SpacingTokens.sm),
                    ...clause.details.map((detail) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '•',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 16,
                                    height: 1.2),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detail,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ))
        else
          Text(
            fallback,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 14,
              height: 1.6,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.privacyTermsHeader,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: ColorTokens.slate400),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ColorTokens.slate800),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: ColorTokens.goldAccent),
                  )
                : ListView(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    children: [
                      _buildClausesSection(AppStrings.termsOfUseLabel,
                          _termsClauses, _termsFallback),
                      SizedBox(height: SpacingTokens.xl),
                      _buildClausesSection(AppStrings.privacyPolicyLabel,
                          _privacyClauses, _privacyFallback),
                      SizedBox(height: SpacingTokens.xxl),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
