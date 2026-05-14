import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 72,
                    color: ColorTokens.goldAccent,
                  ),
                  SizedBox(height: 20),
                  Text(
                    AppStrings.dbKeyMismatchTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 32),

                  // ── Option 1: Enter primary key (mnemonic) ────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: ColorTokens.emerald600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _processing
                          ? null
                          : () => setState(() => _showMnemonicInput = true),
                      icon: Icon(Icons.key, color: Colors.white),
                      label: Text(
                        AppStrings.dbEnterPrimaryKeyAction,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  if (_showMnemonicInput) ...[
                    SizedBox(height: 16),
                    TextField(
                      controller: _mnemonicCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppStrings.dbMnemonicHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
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
                                await widget.onRetryWithMnemonic(
                                    _mnemonicCtrl.text.trim());
                                if (mounted) {
                                  setState(() => _processing = false);
                                }
                              },
                        child: _processing
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppStrings.dbUnlockAction,
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],

                  SizedBox(height: 16),

                  // ── Option 2: Retry with current key ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : widget.onRetry,
                      icon: Icon(Icons.refresh),
                      label: Text(AppStrings.dbRetryAction),
                    ),
                  ),

                  SizedBox(height: 8),

                  // ── Option 3: Start fresh ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _processing
                          ? null
                          : () => _confirmStartFresh(context),
                      icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                      label: Text(
                        AppStrings.dbStartFreshAction,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmStartFresh(BuildContext ctx) {
    QaydDialog.show(
      context: ctx,
      icon: Icons.warning_rounded,
      iconColor: Colors.redAccent,
      title: AppStrings.dbStartFreshConfirmTitle,
      content: AppStrings.dbStartFreshConfirmBody,
      secondaryActionLabel: AppStrings.actionCancel,
      onSecondaryAction: () => Navigator.pop(ctx),
      primaryActionLabel: AppStrings.dbStartFreshConfirmTitle,
      isDestructive: true,
      onPrimaryAction: () {
        Navigator.pop(ctx);
        widget.onStartFresh();
      },
    );
  }
}
