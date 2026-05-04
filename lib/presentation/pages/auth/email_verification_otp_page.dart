import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_error_banner.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class EmailVerificationOtpPage extends StatefulWidget {
  final String email;

  const EmailVerificationOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationOtpPage> createState() =>
      _EmailVerificationOtpPageState();
}

class _EmailVerificationOtpPageState extends State<EmailVerificationOtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _errorAr;

  int _resendTimer = 30;
  Timer? _timer;
  int _resendCount = 0;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
            // It feels more natural to also clear the previous field when jumping back
            _controllers[i - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
    _startTimer();
    _listenForLiveVerification();
  }

  Future<void> _listenForLiveVerification() async {
    final licenseData = await InjectionContainer.licenseVault.readLicenseData();
    final userId = licenseData?['id'] as int?;
    if (userId == null) return;

    // Connect socket if not already connected
    await InjectionContainer.syncSocketService.connect(userId);

    _socketSub =
        InjectionContainer.syncSocketService.socketEvents.listen((event) async {
      if (event['event'] == 'EmailVerified') {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketSub?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      // Exponential backoff match server: 30, 60, 120, 300, 600
      if (_resendCount == 0) {
        _resendTimer = 30;
      } else if (_resendCount == 1) {
        _resendTimer = 60;
      } else if (_resendCount == 2) {
        _resendTimer = 120;
      } else if (_resendCount == 3) {
        _resendTimer = 300;
      } else {
        _resendTimer = 600;
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _resend() async {
    if (_resendTimer > 0 || _resending) return;

    setState(() {
      _resending = true;
      _errorAr = null;
    });

    try {
      final nextRetry =
          await InjectionContainer.authRepository.sendVerificationEmail();
      setState(() {
        _resendCount++;
        _resendTimer = nextRetry;
      });
      _startTimer();
    } on AuthException catch (e) {
      setState(() => _errorAr = e.messageAr);
    } catch (_) {
      setState(() => _errorAr = AppStrings.otpSendError);
    } finally {
      setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _errorAr = AppStrings.pleaseEnterTheFull);
      return;
    }

    setState(() {
      _loading = true;
      _errorAr = null;
    });

    try {
      final success =
          await context.read<SecurityCubit>().verifyEmailOtp(code);
      if (success && mounted) {
        // Success! Return to LoginPage to trigger database initialization.
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      setState(() => _errorAr = e.messageAr);
    } catch (_) {
      setState(() => _errorAr = AppStrings.otpVerifyError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verify();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: ColorTokens.slate400, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
                child: Column(
                  children: [
                    const AuthAnimatedIcon(
                      iconData: Icons.mark_email_read_rounded,
                      iconColor: ColorTokens.emerald500,
                    ),
                    SizedBox(height: SpacingTokens.lg),
                    AuthTitleBlock(
                      title: AppStrings.verificationTitle,
                      subtitle:
                          '${AppStrings.verificationSubtitle}\n${widget.email}',
                    ),
                    SizedBox(height: SpacingTokens.xl),

                    // OTP Input Fields
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            List.generate(6, (index) => _buildOtpBox(index)),
                      ),
                    ),

                    if (_errorAr != null) ...[
                      SizedBox(height: SpacingTokens.md),
                      AuthErrorBanner(message: _errorAr!),
                    ],

                    SizedBox(height: SpacingTokens.xl),

                    AuthSubmitButton(
                      label: AppStrings.verifyAction,
                      loading: _loading,
                      onPressed: _verify,
                    ),

                    SizedBox(height: SpacingTokens.lg),

                    // Resend Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.resendPrompt,
                          style: const TextStyle(
                              color: ColorTokens.slate400, fontSize: 14),
                        ),
                        _resendTimer > 0
                            ? Text(
                                '${AppStrings.resendTimerPrefix}$_resendTimer${AppStrings.resendTimerSuffix}',
                                style: const TextStyle(
                                    color: ColorTokens.emerald500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              )
                            : TextButton(
                                onPressed: _resending ? null : _resend,
                                child: Text(
                                  _resending
                                      ? AppStrings.resending
                                      : AppStrings.resendAction,
                                  style: const TextStyle(
                                      color: ColorTokens.emerald400,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                      ],
                    ),
                    SizedBox(height: SpacingTokens.xxl),

                    // Option to return to login or change email
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.logout_rounded, size: 18),
                      label: Text(AppStrings.returnToLogin),
                      style: TextButton.styleFrom(
                          foregroundColor: ColorTokens.slate400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _focusNodes[index],
      builder: (context, child) {
        final isFocused = _focusNodes[index].hasFocus;
        return Container(
          width: 45,
          height: 60,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? ColorTokens.emerald500 : scheme.outlineVariant,
              width: isFocused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  if (oldValue.text.isNotEmpty) return oldValue;
                  return newValue;
                }),
              ],
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => _onChanged(v, index),
            ),
          ),
        );
      },
    );
  }
}
