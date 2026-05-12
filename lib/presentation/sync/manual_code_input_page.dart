import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

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
  // 8 individual controllers for each character
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Setup backspace handling for jumping back
    for (int i = 0; i < 8; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
            _controllers[i - 1].clear();
            setState(() {});
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredCode =>
      _controllers.map((c) => c.text).join().toUpperCase();

  bool get _isComplete => _enteredCode.length == 8;

  Future<void> _submit() async {
    if (!_isComplete || _isSubmitting) return;
    final code = _enteredCode;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final session =
          await InjectionContainer.companionLinkService.submitViaManualCode(
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
    if (message.contains('INVALID_OR_EXPIRED_CODE') ||
        message.contains('404')) {
      return AppStrings.manualCodeInvalidOrExpired;
    }
    if (message.contains('CODE_LOCKED') || message.contains('429')) {
      return AppStrings.manualCodeTooManyAttempts;
    }
    return AppStrings.companionCredentialsFailed;
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste or multiple characters
      _handleMultipleCharacters(value, index);
      return;
    }

    if (value.isNotEmpty) {
      // Normal single character entry
      if (index < 7) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isComplete) _submit();
      }
    }
    setState(() {});
  }

  void _handleMultipleCharacters(String text, int startIndex) {
    // Sanitize: only alphanumeric and uppercase
    final sanitized =
        text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

    int currentIdx = startIndex;
    for (int i = 0; i < sanitized.length && currentIdx < 8; i++) {
      _controllers[currentIdx].text = sanitized[i];
      currentIdx++;
    }

    // Move focus to the next logical position
    if (currentIdx < 8) {
      _focusNodes[currentIdx].requestFocus();
    } else {
      _focusNodes[7].unfocus();
      if (_isComplete) _submit();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            // Main Centered Content
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.lg),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Extra spacing at top for balance
                          const SizedBox(height: 60),

                          const AuthAnimatedIcon(
                            iconData: Icons.link_rounded,
                            iconColor: ColorTokens.emerald500,
                          ),
                          const SizedBox(height: SpacingTokens.lg),
                          AuthTitleBlock(
                            title: AppStrings.manualCodeInputTitle,
                            subtitle: AppStrings.manualCodeInputInstruction,
                          ),
                          const SizedBox(height: SpacingTokens.xl),

                          // Code input fields
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...List.generate(
                                    4,
                                    (index) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      child: _buildCodeBox(index),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      color: ColorTokens.slate400
                                          .withValues(alpha: 0.5),
                                      size: 16,
                                    ),
                                  ),
                                  ...List.generate(
                                    4,
                                    (index) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      child: _buildCodeBox(index + 4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: SpacingTokens.md),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ColorTokens.errorSoft
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: ColorTokens.errorSoft
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: ColorTokens.errorSoft, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                          color: ColorTokens.errorSoft,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: SpacingTokens.xl),

                          AuthSubmitButton(
                            label: AppStrings.manualCodeSubmit,
                            loading: _isSubmitting,
                            onPressed: _isComplete ? () => _submit() : null,
                          ),

                          const SizedBox(height: SpacingTokens.xxl),

                          Text(
                            AppStrings.manualCodeInputHint,
                            style: const TextStyle(
                              color: ColorTokens.slate400,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Spacing at bottom
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Back Button (Overlaid)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: ColorTokens.slate400, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _focusNodes[index],
      builder: (context, child) {
        final isFocused = _focusNodes[index].hasFocus;
        return Container(
          width: 38,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
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
              if (isFocused)
                BoxShadow(
                  color: ColorTokens.emerald500.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              autofocus: index == 0,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              // Remove maxLength to allow capturing paste/multiple chars
              // We handle length manually in _onChanged
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                _UpperCaseTextFormatter(),
              ],
              onTap: () {
                // Select all text when tapping for easier editing/replacement
                _controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[index].text.length,
                );
              },
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: '•',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
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
