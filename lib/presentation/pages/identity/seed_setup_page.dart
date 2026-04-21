import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:share_plus/share_plus.dart';

class SeedSetupPage extends StatefulWidget {
  const SeedSetupPage({super.key});

  @override
  State<SeedSetupPage> createState() => _SeedSetupPageState();
}

class _SeedSetupPageState extends State<SeedSetupPage> {
  MnemonicPhrase? _mnemonic;
  bool _isLoading = false;

  final SetupIdentityUseCase _setupUseCase =
      InjectionContainer.setupIdentityUseCase;

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  Future<void> _generateMnemonic() async {
    setState(() => _isLoading = true);
    try {
      final hasIdentity = await _setupUseCase.hasIdentity();
      if (!hasIdentity) {
        final phrase = await _setupUseCase.generateAndRegister();
        setState(() => _mnemonic = phrase);
      } else {
        // If they already have an identity but are here, something is odd, 
        // but let's just proceed or re-show.
        // For now, let's assume we need to generate if they are in this flow.
        final phrase = await _setupUseCase.generateAndRegister();
        setState(() => _mnemonic = phrase);
      }
    } catch (e) {
      debugPrint('Seed generation error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyPhrase() async {
    if (_mnemonic == null) return;
    await Clipboard.setData(ClipboardData(text: _mnemonic!.phrase));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStringsAr.identitySeedCopied),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorTokens.emerald600,
      ),
    );
  }

  Future<void> _sharePhrase() async {
    if (_mnemonic == null) return;
    await Share.share(
      _mnemonic!.phrase,
      subject: AppStringsAr.identityShareSeedSubject,
    );
  }

  void _confirmBackup() async {
    setState(() => _isLoading = true);
    try {
      await _setupUseCase.confirmBackup();
      await InjectionContainer.securityCubit.bootCheck();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _mnemonic == null) {
      return const AuthGradientScaffold(
        child: Center(child: CircularProgressIndicator(color: ColorTokens.emerald500)),
      );
    }

    final words = _mnemonic?.words ?? [];

    return AuthGradientScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.lg,
            vertical: SpacingTokens.xl,
          ),
          child: Column(
            children: [
              const AuthAnimatedIcon(
                iconData: Icons.vignette_rounded, // Identity/Seed icon
                iconColor: ColorTokens.emerald500,
              ),
              const SizedBox(height: SpacingTokens.lg),

              AuthTitleBlock(
                title: AppStringsAr.seedSetupTitle,
                subtitle: AppStringsAr.seedSetupBody,
              ),
              const SizedBox(height: SpacingTokens.xl),

              // Warning Box
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: ColorTokens.errorDeep.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorTokens.errorSoft.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: ColorTokens.errorSoft, size: 24),
                    const SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: Text(
                        AppStringsAr.seedBackupWarning,
                        style: const TextStyle(
                          color: ColorTokens.errorSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpacingTokens.xl),

              // Seed Words Grid
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: words.asMap().entries.map((entry) {
                    return _buildWordCard(context, entry.key + 1, entry.value);
                  }).toList(),
                ),
              ),
              const SizedBox(height: SpacingTokens.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      context,
                      icon: Icons.copy_rounded,
                      label: AppStringsAr.identitySeedCopy,
                      onTap: _copyPhrase,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: _buildActionBtn(
                      context,
                      icon: Icons.ios_share_rounded,
                      label: AppStringsAr.identitySeedShare,
                      onTap: _sharePhrase,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.xxl),

              AuthSubmitButton(
                label: AppStringsAr.seedBackupConfirmAction,
                loading: _isLoading,
                onPressed: _confirmBackup,
              ),
              const SizedBox(height: SpacingTokens.lg),

              TextButton(
                onPressed: () => _confirmBackup(), // Skip/Later for now leads to same boot check
                child: Text(
                  AppStringsAr.seedBackupSkipAction,
                  style: TextStyle(color: ColorTokens.slate400.withOpacity(0.7), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, int index, String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minWidth: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index.',
            style: const TextStyle(
              color: ColorTokens.emerald500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            word,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
