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
import 'package:qayd/presentation/pages/identity/seed_recovery_page.dart';

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
    // Do NOT auto-generate in initState to prevent silent registration.
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
    final theme = Theme.of(context);
    if (_isLoading && _mnemonic == null) {
      return const AuthGradientScaffold(
        child: Center(
            child: CircularProgressIndicator(color: ColorTokens.emerald500)),
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
              AuthAnimatedIcon(
                iconData: Icons.vignette_rounded, // Identity/Seed icon
                iconColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: SpacingTokens.lg),
              AuthTitleBlock(
                title: AppStringsAr.seedSetupTitle,
                subtitle: AppStringsAr.seedSetupBody,
              ),
              const SizedBox(height: SpacingTokens.xl),
              if (_mnemonic == null) ...[
                _buildIntroSection(context),
              ] else ...[
                // ── Warning Banner (Professional Style) ─────────────────────────
                _buildWarningBanner(context),
                const SizedBox(height: SpacingTokens.xl),

                // ── Seed Words Grid (Professional Style) ────────────────────────
                _buildSectionLabel(context, AppStringsAr.identityViewSeed),
                const SizedBox(height: SpacingTokens.sm),
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.05)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: words.asMap().entries.map((entry) {
                      return _buildWordCard(
                          context, entry.key + 1, entry.value);
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
                  onPressed: () => _confirmBackup(),
                  child: Text(
                    AppStringsAr.seedBackupSkipAction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    return Column(
      children: [
        const Text(
          'سيتم الآن إنشاء هوية رقمية جديدة لتأمين وتشفير بياناتك على هذا الجهاز.',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: ColorTokens.slate400, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: SpacingTokens.xl),
        AuthSubmitButton(
          label: 'لدي مفتاح سابق (24 كلمة) بالفعل',
          loading: _isLoading,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SeedRecoveryPage()),
            );
          },
        ),
        const SizedBox(height: SpacingTokens.lg),
        TextButton(
          onPressed: _generateMnemonic,
          child: const Text(
            'إنشاء هوية جديدة',
            style: TextStyle(
              color: ColorTokens.emerald500,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm, right: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withValues(alpha: 0.12),
            theme.colorScheme.error.withValues(alpha: 0.06),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 22,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحذير الأمان',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStringsAr.seedBackupWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, int index, String word) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index.',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            word,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
              fontFamily: 'monospace',
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
