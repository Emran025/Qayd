import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/collateral_revaluation.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/attachment_gallery_dialog.dart';

/// Dialog showing collateral details, photos, valuation history, and
/// action buttons for re-evaluation and liquidation.
class CollateralDetailDialog extends StatelessWidget {
  const CollateralDetailDialog({
    super.key,
    required this.collateral,
    this.revaluations = const [],
    this.decryptedImages = const [],
    this.imageNames = const [],
    this.onRevaluate,
    this.onLiquidate,
  });

  final Collateral collateral;
  final List<CollateralRevaluation> revaluations;

  /// Decrypted collateral images for gallery viewing.
  final List<Uint8List> decryptedImages;
  final List<String> imageNames;

  /// Callback for the "Re-evaluate" action.
  final VoidCallback? onRevaluate;

  /// Callback for the "Liquidate / عرض للبيع" action.
  final VoidCallback? onLiquidate;

  static Future<void> show(
    BuildContext context, {
    required Collateral collateral,
    List<CollateralRevaluation> revaluations = const [],
    List<Uint8List> decryptedImages = const [],
    List<String> imageNames = const [],
    VoidCallback? onRevaluate,
    VoidCallback? onLiquidate,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CollateralDetailDialog(
        collateral: collateral,
        revaluations: revaluations,
        decryptedImages: decryptedImages,
        imageNames: imageNames,
        onRevaluate: onRevaluate,
        onLiquidate: onLiquidate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = ColorTokens.goldAccent;
    final theme = Theme.of(context);
    final valueStr = NumberFormat.decimalPattern('ar')
        .format(collateral.estimatedValue.minorUnits / 100);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: gold, size: 28),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'تفاصيل الرهن',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusBadge(status: collateral.status.name),
                ],
              ),
              const SizedBox(height: SpacingTokens.lg),

              // ── Description ──────────────────────────────────────
              _InfoRow(
                icon: Icons.description_rounded,
                label: 'الوصف',
                value: collateral.description,
              ),
              const SizedBox(height: SpacingTokens.md),

              // ── Value ────────────────────────────────────────────
              _InfoRow(
                icon: Icons.attach_money_rounded,
                label: 'القيمة التقديرية',
                value:
                    '$valueStr ${collateral.currency.code}',
              ),
              const SizedBox(height: SpacingTokens.md),

              // ── Expiry ───────────────────────────────────────────
              if (collateral.expiryDate != null) ...[
                _InfoRow(
                  icon: Icons.event_rounded,
                  label: 'تاريخ الاستحقاق',
                  value: DateFormat.yMMMd('ar')
                      .format(collateral.expiryDate!),
                  valueColor: collateral.isExpired ? theme.colorScheme.error : null,
                ),
                if (collateral.isExpired)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: SpacingTokens.xs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_rounded,
                              size: 16, color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 6),
                          Text(
                            'منتهي الصلاحية',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: SpacingTokens.md),
              ],

              // ── Collateral images ────────────────────────────────
              if (decryptedImages.isNotEmpty) ...[
                Text(
                  'صور الرهن',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: SpacingTokens.sm),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: decryptedImages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: SpacingTokens.sm),
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () => AttachmentGalleryDialog.show(
                          context,
                          imageBytes: decryptedImages,
                          fileNames: imageNames,
                          initialIndex: i,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            decryptedImages[i],
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: SpacingTokens.md),
              ],

              // ── Revaluation history ──────────────────────────────
              if (revaluations.isNotEmpty) ...[
                Text(
                  'سجل إعادة التقييم',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: SpacingTokens.sm),
                ...revaluations.map((r) => _RevaluationTile(reval: r)),
                const SizedBox(height: SpacingTokens.md),
              ],

              // ── Actions ──────────────────────────────────────────
              if (!collateral.isTerminal) ...[
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: SpacingTokens.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRevaluate,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: gold.withValues(alpha: 0.5)),
                        ),
                        icon: Icon(Icons.edit_rounded,
                            size: 18, color: gold),
                        label: Text(
                          'إعادة تقييم',
                          style: TextStyle(color: gold),
                        ),
                      ),
                    ),
                    if (collateral.canLiquidate) ...[
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onLiquidate,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          icon: const Icon(Icons.gavel_rounded, size: 18),
                          label: const Text('عرض للبيع'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.outline),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, label) = switch (status) {
      'active' => (Colors.green, 'نشط'),
      'expired' => (Colors.orange, 'منتهي'),
      'liquidated' => (scheme.error, 'تمت التصفية'),
      'released' => (Colors.blue, 'محرر'),
      _ => (scheme.outline, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RevaluationTile extends StatelessWidget {
  const _RevaluationTile({required this.reval});

  final CollateralRevaluation reval;

  @override
  Widget build(BuildContext context) {
    final oldVal = NumberFormat.decimalPattern('ar')
        .format(reval.oldValueMinor / 100);
    final newVal = NumberFormat.decimalPattern('ar')
        .format(reval.newValueMinor / 100);
    final delta = reval.valueDelta;
    final scheme = Theme.of(context).colorScheme;
    final deltaStr = delta >= 0 ? '+${delta / 100}' : '${delta / 100}';
    final deltaColor =
        delta >= 0 ? Colors.green : scheme.error;
    final dateStr = DateFormat.yMMMd('ar').format(reval.evaluatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_flat_rounded, size: 16, color: deltaColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$oldVal → $newVal ($deltaStr)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            dateStr,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
