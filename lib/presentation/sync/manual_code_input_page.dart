import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// COMPANION DEVICE screen.
///
/// The user types the 8-character code shown on the Primary device.
/// Once submitted, the companion's ephemeral key is sent to the server.
/// The companion then polls for the bootstrap payload exactly as in the QR flow.
///
/// Callback [onSessionReady] is called with the [CompanionLinkSession] so
/// the parent ([CompanionLinkPage]) can hand off to its existing polling logic.
class ManualCodeInputPage extends StatefulWidget {
  const ManualCodeInputPage({
    super.key,
    required this.onSessionReady,
  });

  final void Function(CompanionLinkSession session) onSessionReady;

  @override
  State<ManualCodeInputPage> createState() => _ManualCodeInputPageState();
}

class _ManualCodeInputPageState extends State<ManualCodeInputPage> {
  // Two controllers: first half (4 chars) and second half (4 chars).
  // Displayed as "ABCD - EFGH" — matching the Primary's display format.
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  final _firstFocus = FocusNode();
  final _secondFocus = FocusNode();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    _firstFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  String get _enteredCode =>
      (_firstController.text + _secondController.text).toUpperCase().replaceAll(' ', '');

  bool get _isComplete => _enteredCode.length == 8;

  Future<void> _submit() async {
    if (!_isComplete || _isSubmitting) return;
    final code = _enteredCode;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final session = await InjectionContainer.companionLinkService.submitViaManualCode(
        shortCode: code,
        manualLinkService: InjectionContainer.manualLinkService,
      );
      if (!mounted) return;
      widget.onSessionReady(session);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = _mapError(e.toString());
      });
    }
  }

  String _mapError(String message) {
    if (message.contains('INVALID_OR_EXPIRED_CODE') || message.contains('404')) {
      return AppStrings.manualCodeInvalidOrExpired;
    }
    if (message.contains('CODE_LOCKED') || message.contains('429')) {
      return AppStrings.manualCodeTooManyAttempts;
    }
    return AppStrings.companionCredentialsFailed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.manualCodeInputTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.keyboard_rounded, size: 52, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                AppStrings.manualCodeInputInstruction,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSegment(
                    controller: _firstController,
                    focusNode: _firstFocus,
                    onComplete: () => _secondFocus.requestFocus(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '—',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _buildSegment(
                    controller: _secondController,
                    focusNode: _secondFocus,
                    onComplete: _submit,
                  ),
                ],
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _error!,
                        style: TextStyle(color: colorScheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isComplete && !_isSubmitting) ? _submit : null,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.link_rounded),
                  label: Text(
                    _isSubmitting
                        ? AppStrings.manualCodeSubmitting
                        : AppStrings.manualCodeSubmit,
                  ),
                ),
              ),

              const Spacer(),

              // Helper text
              Text(
                AppStrings.manualCodeInputHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onComplete,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFirst = controller == _firstController;

    return SizedBox(
      width: 140,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: isFirst,
        maxLength: 4,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        keyboardType: TextInputType.text,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          _UpperCaseTextFormatter(),
        ],
        style: theme.textTheme.headlineSmall?.copyWith(
          letterSpacing: 8,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        ),
        onChanged: (val) {
          setState(() {});
          if (val.length == 4) onComplete();
        },
      ),
    );
  }
}

/// Forces input to uppercase.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
