import 'package:flutter/material.dart';
import 'package:qayd/application/identity/setup_identity_use_case.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class SeedRecoveryPage extends StatefulWidget {
  const SeedRecoveryPage({super.key});

  @override
  State<SeedRecoveryPage> createState() => _SeedRecoveryPageState();
}

class _SeedRecoveryPageState extends State<SeedRecoveryPage> {
  final _phraseController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  final SetupIdentityUseCase _setupUseCase =
      InjectionContainer.setupIdentityUseCase;

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final text = _phraseController.text.trim();
      if (text.isEmpty) {
        setState(() => _error = AppStringsAr.identityRecoveryInputRequired);
        return;
      }

      final phrase = MnemonicPhrase.fromPhrase(text);
      await _setupUseCase.recoverFromMnemonic(phrase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStringsAr.seedRecoverySuccess)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = AppStringsAr.seedRecoveryInvalid);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: ColorTokens.slate400, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                  vertical: SpacingTokens.md,
                ),
                child: Column(
                  children: [
                    const AuthAnimatedIcon(
                      iconData: Icons.vibration_rounded,
                      iconColor: ColorTokens.emerald500,
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    const AuthTitleBlock(
                      title: AppStringsAr.seedRecoveryTitle,
                      subtitle: AppStringsAr.seedRecoveryBody,
                    ),
                    const SizedBox(height: SpacingTokens.xl),
                    TextField(
                      controller: _phraseController,
                      maxLines: 5,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                      cursorColor: ColorTokens.emerald500,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B), // Slate 800
                        hintText: 'word1 word2 word3 ...',
                        hintStyle: const TextStyle(color: ColorTokens.slate400),
                        errorText: _error,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ColorTokens.emerald500.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ColorTokens.emerald500,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xl),
                    AuthSubmitButton(
                      label: AppStringsAr.seedRecoveryAction,
                      loading: _isLoading,
                      onPressed: _recover,
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    const Text(
                      AppStringsAr.identityRecoveryHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorTokens.slate400,
                        fontSize: 12,
                      ),
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
}
