import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/domain/value_objects/income_source_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// A rich card for displaying an income stream or possession account.
///
/// Adapts its visual style and KPI indicators based on the
/// `income_source_type` stored in the account metadata.
class IncomeStreamCard extends StatelessWidget {
  const IncomeStreamCard({super.key, required this.account, this.onTap});

  final AccountSummaryDto account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metadata = account.metadata ?? {};
    final sourceTypeKey = metadata['income_source_type'] as String?;
    final sourceType = IncomeSourceType.fromKey(sourceTypeKey);

    final typeInfo = _resolveTypeInfo(sourceType, account);

    // Format balance
    int balanceMinor = 0;
    String cur = 'SAR';
    if (account.balancesMinorUnits.isNotEmpty) {
      cur = account.balancesMinorUnits.keys.first;
      balanceMinor = account.balancesMinorUnits[cur]!;
    }
    final balance = balanceMinor / 100.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: typeInfo.color.withValues(alpha: 0.15),
        ),
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: typeInfo.color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Top accent
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(RadiusTokens.lg),
                ),
                gradient: LinearGradient(
                  colors: [
                    typeInfo.color.withValues(alpha: 0.8),
                    typeInfo.color.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Name + Type Badge
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeInfo.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                        ),
                        child: Icon(typeInfo.icon,
                            color: typeInfo.color, size: 22),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            QaydText(
                              account.name,
                              slot: QaydTextStyleSlot.titleSmall,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeInfo.color.withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.xs),
                              ),
                              child: Text(
                                typeInfo.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: typeInfo.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_left_rounded,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ],
                  ),

                  const SizedBox(height: SpacingTokens.sm),
                  const Divider(height: 1),
                  const SizedBox(height: SpacingTokens.sm),

                  // KPI Row
                  Row(
                    children: [
                      _KpiChip(
                        label: _balanceLabel(sourceType),
                        value: '${balance.toStringAsFixed(2)} $cur',
                        color: balance >= 0
                            ? ColorTokens.emerald500
                            : ColorTokens.errorSoft,
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      if (metadata['purchase_price'] != null)
                        _KpiChip(
                          label: AppStringsAr.incomeStreamAcquisitionValue,
                          value:
                              '${(metadata['purchase_price'] as num).toStringAsFixed(0)} $cur',
                          color: scheme.onSurfaceVariant,
                        ),
                      if (metadata['profession_name'] != null)
                        _KpiChip(
                          label: AppStringsAr.incomeStreamProfessionField,
                          value: metadata['profession_name'] as String,
                          color: ColorTokens.debitBlue,
                        ),
                    ],
                  ),

                  // Secondary metadata row
                  if (_hasSecondaryInfo(metadata)) ...[
                    const SizedBox(height: SpacingTokens.xs),
                    Wrap(
                      spacing: SpacingTokens.md,
                      runSpacing: 2,
                      children: [
                        if (metadata['start_date'] != null)
                          _MetaLabel(
                            icon: Icons.calendar_today_rounded,
                            text:
                                '${(metadata['start_date'] as String).split('T').first}',
                          ),
                        if (metadata['hourly_rate'] != null)
                          _MetaLabel(
                            icon: Icons.timer_outlined,
                            text:
                                '${(metadata['hourly_rate'] as num).toStringAsFixed(0)} /ساعة',
                          ),
                        if (metadata['license_number'] != null &&
                            (metadata['license_number'] as String).isNotEmpty)
                          _MetaLabel(
                            icon: Icons.badge_outlined,
                            text: metadata['license_number'] as String,
                          ),
                        if (metadata['purchase_date'] != null)
                          _MetaLabel(
                            icon: Icons.calendar_today_rounded,
                            text:
                                '${(metadata['purchase_date'] as String).split('T').first}',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  bool _hasSecondaryInfo(Map<String, dynamic> m) =>
      m['start_date'] != null ||
      m['hourly_rate'] != null ||
      m['license_number'] != null ||
      m['purchase_date'] != null;

  String _balanceLabel(IncomeSourceType? type) {
    return switch (type) {
      IncomeSourceType.investmentAsset => AppStringsAr.incomeStreamTotalYield,
      IncomeSourceType.profession => AppStringsAr.incomeStreamTotalEarned,
      IncomeSourceType.possession => AppStringsAr.incomeStreamCurrentValue,
      IncomeSourceType.other => AppStringsAr.incomeStreamTotalEarned,
      null => AppStringsAr.incomeStreamBalance,
    };
  }

  _TypeInfo _resolveTypeInfo(
      IncomeSourceType? type, AccountSummaryDto account) {
    return switch (type) {
      IncomeSourceType.investmentAsset => _TypeInfo(
          icon: Icons.account_balance_rounded,
          color: ColorTokens.emerald500,
          label: AppStringsAr.incomeSourceInvestmentAsset,
        ),
      IncomeSourceType.profession => _TypeInfo(
          icon: Icons.work_outline_rounded,
          color: ColorTokens.debitBlue,
          label: AppStringsAr.incomeSourceProfession,
        ),
      IncomeSourceType.other => _TypeInfo(
          icon: Icons.monetization_on_outlined,
          color: ColorTokens.warningAmber,
          label: AppStringsAr.incomeSourceOther,
        ),
      IncomeSourceType.possession => _TypeInfo(
          icon: Icons.inventory_2_outlined,
          color: ColorTokens.slate400,
          label: AppStringsAr.incomeSourcePossession,
        ),
      null => _TypeInfo(
          icon: _fallbackIcon(account.standardClassificationKind),
          color: _fallbackColor(account.standardClassificationKind),
          label: _fallbackLabel(account.standardClassificationKind),
        ),
    };
  }

  IconData _fallbackIcon(String? kind) => switch (kind) {
        'personalExpenses' => Icons.receipt_long_outlined,
        'personalRevenues' => Icons.trending_up_rounded,
        'fixedProfitableAssets' => Icons.account_balance_rounded,
        'fixedDepreciableAssets' => Icons.inventory_2_outlined,
        _ => Icons.folder_outlined,
      };

  Color _fallbackColor(String? kind) => switch (kind) {
        'personalExpenses' => ColorTokens.errorSoft,
        'personalRevenues' => ColorTokens.emerald500,
        'fixedProfitableAssets' => ColorTokens.emerald500,
        'fixedDepreciableAssets' => ColorTokens.slate400,
        _ => ColorTokens.navy700,
      };

  String _fallbackLabel(String? kind) => switch (kind) {
        'personalExpenses' => AppStringsAr.incomeStreamExpenseCategory,
        'personalRevenues' => AppStringsAr.incomeSourceOther,
        _ => '',
      };
}

class _TypeInfo {
  const _TypeInfo({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}
