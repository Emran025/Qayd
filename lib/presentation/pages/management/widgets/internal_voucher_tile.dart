import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class InternalVoucherTile extends StatelessWidget {
  const InternalVoucherTile({
    super.key,
    required this.dto,
    required this.onTap,
  });

  final VoucherSummaryDto dto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReceipt = dto.typeCode == 'receipt';
    final icon =
        isReceipt ? Icons.south_west_rounded : Icons.north_east_rounded;
    final iconBg = isReceipt
        ? ColorTokens.emerald600.withValues(alpha: 0.2)
        : ColorTokens.goldAccent.withValues(alpha: 0.22);
    final iconFg = isReceipt ? ColorTokens.emerald700 : ColorTokens.navy900;

    final dateStr = DateFormat.yMMMd('ar').format(DateTime.parse(dto.dateIso));

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: iconBg,
                    foregroundColor: iconFg,
                    child: Icon(icon, size: 22),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            QaydText(
                              isReceipt ? 'إيراد / توريد' : 'مصروف / صرف نقدية',
                              slot: QaydTextStyleSlot.labelLarge,
                              color: scheme.onSurfaceVariant,
                            ),
                            QaydText(
                              dateStr,
                              slot: QaydTextStyleSlot.bodySmall,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        QaydText(
                          dto.counterpartyName,
                          slot: QaydTextStyleSlot.titleMedium,
                        ),
                        if (dto.description != null &&
                            dto.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: QaydText(
                              dto.description!,
                              slot: QaydTextStyleSlot.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      QaydText(
                        (dto.amountMinorUnits / 100).toStringAsFixed(2),
                        slot: QaydTextStyleSlot.titleMedium,
                      ),
                      QaydText(
                        dto.currencyCode,
                        slot: QaydTextStyleSlot.labelSmall,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
