import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/identity/seed_setup_page.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:share_plus/share_plus.dart';

/// Displays identity key information and allows the user to copy or share
/// their mnemonic recovery phrase and view their public key.
class IdentitySettingsSection extends StatefulWidget {
  const IdentitySettingsSection({super.key});

  @override
  State<IdentitySettingsSection> createState() =>
      _IdentitySettingsSectionState();
}

class _IdentitySettingsSectionState extends State<IdentitySettingsSection> {
  bool _loading = true;
  bool _hasIdentity = false;
  String? _publicKeyHex;
  int _keyGeneration = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final vault = InjectionContainer.mnemonicVault;
    final hasId = await vault.hasIdentity();
    final kp = hasId ? await vault.readKeyPair() : null;
    final gen = await vault.readKeyGeneration();
    if (!mounted) return;
    setState(() {
      _hasIdentity = hasId;
      _publicKeyHex = kp?.publicKeyHex;
      _keyGeneration = gen;
      _loading = false;
    });
  }

  // ── Mnemonic actions ──────────────────────────────────────────────────────

  Future<void> _showMnemonicWarning() async {
    final go = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.warning_amber_rounded,
      title: AppStringsAr.identityViewSeedWarningTitle,
      content: AppStringsAr.identityViewSeedWarningBody,
      secondaryActionLabel: AppStringsAr.templateEditCancel,
      onSecondaryAction: () => Navigator.pop(context, false),
      primaryActionLabel: AppStringsAr.settingsProceed,
      onPrimaryAction: () => Navigator.pop(context, true),
    );
    if (go != true || !mounted) return;
    await _revealMnemonic();
  }

  Future<void> _revealMnemonic() async {
    final vault = InjectionContainer.mnemonicVault;
    final mnemonic = await vault.readMnemonic();
    if (!mounted) return;
    if (mnemonic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.identityNotSetup)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _MnemonicDialog(mnemonic: mnemonic),
    );
  }

  // ── Public key ────────────────────────────────────────────────────────────

  Future<void> _copyPublicKey() async {
    if (_publicKeyHex == null) return;
    await Clipboard.setData(ClipboardData(text: _publicKeyHex!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStringsAr.identityPublicKeyCopied)),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(SpacingTokens.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasIdentity) {
      return Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          children: [
            Text(
              AppStringsAr.identityNotSetup,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                QaydPageRoute.slideFromStart(
                    builder: (_) => const SeedSetupPage()),
              ),
              icon: const Icon(Icons.vpn_key_outlined),
              label: Text(AppStringsAr.identitySetupAction),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: Text(AppStringsAr.identityViewSeed),
          subtitle: Text(AppStringsAr.identityViewSeedSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showMnemonicWarning,
        ),
        ListTile(
          leading: const Icon(Icons.fingerprint_rounded),
          title: Text(AppStringsAr.identityPublicKeyLabel),
          subtitle: _publicKeyHex != null
              ? Text(
                  '${_publicKeyHex!.substring(0, 16)}…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                )
              : null,
          trailing: IconButton(
            tooltip: AppStringsAr.identityPublicKeyCopy,
            icon: const Icon(Icons.copy_outlined),
            onPressed: _publicKeyHex != null ? _copyPublicKey : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.xs,
          ),
          child: Text(
            '${AppStringsAr.identityKeyGenerationLabel}: $_keyGeneration',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.sync_rounded),
          title: const Text('رمز مزامنة P2P (Snap-Sync)'),
          subtitle:
              const Text('لربط جهازين مباشرة عبر الشبكة المحلية دون إنترنت.'),
          trailing: const Icon(Icons.qr_code_2_rounded),
          onTap: _showP2PCode,
        ),
      ],
    );
  }

  void _showP2PCode() {
    QaydDialog.show<void>(
      context: context,
      icon: Icons.qr_code_2_rounded,
      title: 'مزامنة Snap-Sync',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'امسح هذا الرمز من الجهاز الآخر لبدء المزامنة المباشرة عالية السرعة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'IP: (جارٍ اكتشاف الشبكة…)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      primaryActionLabel: 'إغلاق',
      onPrimaryAction: () => Navigator.pop(context),
    );
  }
}

// ── Mnemonic dialog ────────────────────────────────────────────────────────

class _MnemonicDialog extends StatelessWidget {
  const _MnemonicDialog({required this.mnemonic});

  final MnemonicPhrase mnemonic;

  List<String> get _words => mnemonic.phrase.trim().split(' ');

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: mnemonic.phrase));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStringsAr.identitySeedCopied)),
    );
  }

  Future<void> _share() async {
    await Share.share(
      mnemonic.phrase,
      subject: AppStringsAr.identityShareSeedSubject,
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    return QaydDialog(
      icon: Icons.vpn_key_outlined,
      title: AppStringsAr.identityViewSeed,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStringsAr.identitySeedDialogBody,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.md),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < words.length; i++)
                      _WordChip(index: i + 1, word: words[i]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStringsAr.identitySeedWarning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      secondaryActionLabel: AppStringsAr.identitySeedShare,
      onSecondaryAction: () => _share(),
      tertiaryActionLabel: AppStringsAr.identitySeedCopy,
      onTertiaryAction: () => _copy(context),
      primaryActionLabel: AppStringsAr.settingsUnderstood,
      onPrimaryAction: () => Navigator.pop(context),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.index, required this.word});

  final int index;
  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            word,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
