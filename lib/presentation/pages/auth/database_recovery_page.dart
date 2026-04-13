import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// Recovery screen shown when the SQLCipher database key doesn't match
/// the existing encrypted file.
///
/// Offers three paths:
///   1. Enter the primary key (24-word mnemonic) to derive the correct key.
///   2. Retry with the current key (e.g. after re-provisioning).
///   3. Delete the existing database and start fresh.
class DatabaseRecoveryPage extends StatefulWidget {
  const DatabaseRecoveryPage({
    super.key,
    required this.errorMessage,
    required this.onRetryWithMnemonic,
    required this.onStartFresh,
    required this.onRetry,
  });

  final String errorMessage;
  final Future<void> Function(String mnemonic) onRetryWithMnemonic;
  final VoidCallback onStartFresh;
  final VoidCallback onRetry;

  @override
  State<DatabaseRecoveryPage> createState() => _DatabaseRecoveryPageState();
}

class _DatabaseRecoveryPageState extends State<DatabaseRecoveryPage> {
  final _mnemonicCtrl = TextEditingController();
  bool _showMnemonicInput = false;
  bool _processing = false;

  @override
  void dispose() {
    _mnemonicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: ColorTokens.goldAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  AppStringsAr.dbKeyMismatchTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Option 1: Enter primary key (mnemonic) ────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.emerald600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _processing
                        ? null
                        : () => setState(() => _showMnemonicInput = true),
                    icon: const Icon(Icons.key, color: Colors.white),
                    label: Text(
                      AppStringsAr.dbEnterPrimaryKeyAction,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                if (_showMnemonicInput) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mnemonicCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppStringsAr.dbMnemonicHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.emerald600,
                      ),
                      onPressed: _processing
                          ? null
                          : () async {
                              if (_mnemonicCtrl.text.trim().isEmpty) return;
                              setState(() => _processing = true);
                              await widget
                                  .onRetryWithMnemonic(_mnemonicCtrl.text.trim());
                              if (mounted) setState(() => _processing = false);
                            },
                      child: _processing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppStringsAr.dbUnlockAction,
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Option 2: Retry with current key ──────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppStringsAr.dbRetryAction),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Option 3: Start fresh ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _confirmStartFresh(context),
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                    label: Text(
                      AppStringsAr.dbStartFreshAction,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmStartFresh(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppStringsAr.dbStartFreshConfirmTitle),
        content: Text(AppStringsAr.dbStartFreshConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppStringsAr.actionCancel),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onStartFresh();
            },
            child: Text(
              AppStringsAr.dbStartFreshConfirmAction,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
