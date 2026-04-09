import 'package:flutter/material.dart';
import 'package:qayd/application/identity/setup_identity_use_case.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final text = _phraseController.text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'الرجاء إدخال عبارة الاسترداد');
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QaydAppBar(title: AppStringsAr.seedRecoveryTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStringsAr.seedRecoveryBody,
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextField(
              controller: _phraseController,
              decoration: InputDecoration(
                labelText: 'عبارة الاسترداد (24 كلمة مسافة بينهم)',
                hintText: 'word1 word2 word3 ...',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _recover,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(AppStringsAr.seedRecoveryAction),
            ),
          ],
        ),
      ),
    );
  }
}
