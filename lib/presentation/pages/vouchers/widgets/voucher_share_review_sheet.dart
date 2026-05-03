import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


class VoucherSharePreviewSheet extends StatefulWidget {
  final String initialText;

  const VoucherSharePreviewSheet({
    super.key,
    required this.initialText,
  });

  static Future<String?> show(BuildContext context, String text) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoucherSharePreviewSheet(initialText: text),
    );
  }

  @override
  State<VoucherSharePreviewSheet> createState() =>
      _VoucherSharePreviewSheetState();
}

class _VoucherSharePreviewSheetState extends State<VoucherSharePreviewSheet> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md + viewInsets,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: gold),
              const SizedBox(width: SpacingTokens.sm),
              QaydText(
                AppStringsAr.reviewAndEditThe,
                slot: QaydTextStyleSlot.titleMedium,
                color: scheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: _isEditing ? scheme.surface : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isEditing
                    ? gold
                    : scheme.outlineVariant.withValues(alpha: 0.5),
                width: _isEditing ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => setState(() => _isEditing = true),
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      maxLines: 8,
                      minLines: 3,
                      autofocus: true,
                      style: theme.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QaydText(
                          _controller.text,
                          slot: QaydTextStyleSlot.bodyMedium,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 14, color: gold.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            QaydText(
                              AppStringsAr.clickToEdit,
                              slot: QaydTextStyleSlot.labelSmall,
                              color: gold.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStringsAr.cancellation),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _controller.text),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(AppStringsAr.confirmAndSend),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: ColorTokens.navy950,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
