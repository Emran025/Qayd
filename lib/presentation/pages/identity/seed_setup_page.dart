import 'package:flutter/material.dart';
import 'package:qayd/application/identity/setup_identity_use_case.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

class SeedSetupPage extends StatefulWidget {
  const SeedSetupPage({super.key});

  @override
  State<SeedSetupPage> createState() => _SeedSetupPageState();
}

class _SeedSetupPageState extends State<SeedSetupPage> {
  MnemonicPhrase? _mnemonic;
  bool _isLoading = false;
  bool _backupConfirmed = false;

  final SetupIdentityUseCase _setupUseCase = InjectionContainer.setupIdentityUseCase;

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
        // If they already have an identity, we shouldn't show the setup page
        // but maybe just let them copy the phrase if they haven't confirmed
        // For simplicity, let's just mark confirmed.
        setState(() => _backupConfirmed = true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmBackup() async {
    await _setupUseCase.confirmBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.seedBackupConfirmed)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_backupConfirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStringsAr.seedSetupTitle)),
        body: const Center(child: Text(AppStringsAr.seedBackupConfirmed)),
      );
    }

    final words = _mnemonic?.words ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStringsAr.seedSetupTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStringsAr.seedSetupBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStringsAr.seedBackupWarning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8.0,
              runSpacing: 12.0,
              children: words.asMap().entries.map((entry) {
                return Chip(
                  label: Text('${entry.key + 1}. \${entry.value}'),
                  backgroundColor: theme.colorScheme.surfaceVariant,
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _confirmBackup,
              child: const Text('أكّدت حفظ العبارة'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لاحقاً (غير مستحسن)'),
            ),
          ],
        ),
      ),
    );
  }
}
