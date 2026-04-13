import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/cost_centers/dtos/center_voucher_summary.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';

/// A clean timeline-style transaction tile.
///
/// Instead of heavy cards, each tile uses a thin coloured accent bar on the
/// leading edge and minimal chrome. Amount is coloured by direction (debit
/// blue / credit green) with a tiny directional arrow inline.
class TransactionHistoryTile extends StatelessWidget {
  const TransactionHistoryTile({
    super.key,
    required this.summary,
    this.animationValue = 1.0,
    this.isLast = false,
  });

  final CenterVoucherSummary summary;
  final double animationValue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isReceipt = summary.type == VoucherType.receipt;
    final accent =
        isReceipt ? ColorTokens.debitBlue : ColorTokens.creditGreen;

    return Opacity(
      opacity: animationValue.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - animationValue)),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: isLast ? 0 : SpacingTokens.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Accent bar + timeline dot ────────────────────
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Icon(
                        isReceipt
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 14,
                        color: accent,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1.5,
                        height: 36,
                        margin: const EdgeInsets.only(top: 4),
                        color: scheme.onSurface.withValues(alpha: 0.05),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: SpacingTokens.sm + 2),

              // ── Content ─────────────────────────────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  decoration: isLast
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: scheme.onSurface.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.counterpartyName ??
                                  AppStringsAr.voucherStateConfirmed,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (summary.description?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 2),
                              Text(
                                summary.description!,
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('yyyy/MM/dd').format(summary.date),
                              style: tt.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text.rich(
                          buildNumericalScaledSpan(
                            '${isReceipt ? '+' : '-'}${summary.amountMinor ~/ 100} ${summary.currencyCode}',
                            TextStyle(
                              fontWeight: FontWeight.w800,
                              color: accent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds an animated list of [TransactionHistoryTile]s with staggered entry.
class TransactionHistoryList extends StatefulWidget {
  const TransactionHistoryList({
    super.key,
    required this.vouchers,
  });

  final List<CenterVoucherSummary> vouchers;

  @override
  State<TransactionHistoryList> createState() => _TransactionHistoryListState();
}

class _TransactionHistoryListState extends State<TransactionHistoryList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 350 + (widget.vouchers.length * 60).clamp(0, 600),
      ),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant TransactionHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vouchers != widget.vouchers) {
      _ctrl
        ..duration = Duration(
          milliseconds: 350 + (widget.vouchers.length * 60).clamp(0, 600),
        )
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.vouchers.length;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          children: List.generate(total, (i) {
            final start = (i / (total + 1)).clamp(0.0, 1.0);
            final end = ((i + 1.5) / (total + 1)).clamp(0.0, 1.0);
            final t = Interval(start, end, curve: Curves.easeOutCubic)
                .transform(_ctrl.value);
            return TransactionHistoryTile(
              summary: widget.vouchers[i],
              animationValue: t,
              isLast: i == total - 1,
            );
          }),
        );
      },
    );
  }
}
