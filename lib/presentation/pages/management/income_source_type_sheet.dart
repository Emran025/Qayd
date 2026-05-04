import 'package:flutter/material.dart';
import 'package:qayd/domain/value_objects/income_source_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Bottom sheet that lets the user pick what kind of income source to add.
Future<IncomeSourceType?> showIncomeSourceTypeSheet(BuildContext context) {
  return showModalBottomSheet<IncomeSourceType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => const _IncomeSourceTypeBody(),
  );
}

class _IncomeSourceTypeBody extends StatelessWidget {
  const _IncomeSourceTypeBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        0,
        SpacingTokens.lg,
        bottomPad + SpacingTokens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaydText(
            AppStrings.incomeSourceTypeSheetTitle,
            slot: QaydTextStyleSlot.titleLarge,
          ),
          SizedBox(height: SpacingTokens.xs),
          QaydText(
            AppStrings.incomeSourceTypeSheetSubtitle,
            slot: QaydTextStyleSlot.bodySmall,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(height: SpacingTokens.lg),

          _SourceTypeTile(
            icon: Icons.account_balance_rounded,
            color: ColorTokens.emerald500,
            title: AppStrings.incomeSourceInvestmentAsset,
            subtitle: AppStrings.incomeSourceInvestmentAssetDesc,
            onTap: () =>
                Navigator.pop(context, IncomeSourceType.investmentAsset),
          ),
          SizedBox(height: SpacingTokens.sm),

          _SourceTypeTile(
            icon: Icons.work_outline_rounded,
            color: ColorTokens.debitBlue,
            title: AppStrings.incomeSourceProfession,
            subtitle: AppStrings.incomeSourceProfessionDesc,
            onTap: () => Navigator.pop(context, IncomeSourceType.profession),
          ),
          SizedBox(height: SpacingTokens.sm),

          _SourceTypeTile(
            icon: Icons.monetization_on_outlined,
            color: ColorTokens.warningAmber,
            title: AppStrings.incomeSourceOther,
            subtitle: AppStrings.incomeSourceOtherDesc,
            onTap: () => Navigator.pop(context, IncomeSourceType.other),
          ),
          SizedBox(height: SpacingTokens.sm),

           Divider(height: 1),
          SizedBox(height: SpacingTokens.sm),

          _SourceTypeTile(
            icon: Icons.inventory_2_outlined,
            color: ColorTokens.slate400,
            title: AppStrings.incomeSourcePossession,
            subtitle: AppStrings.incomeSourcePossessionDesc,
            onTap: () => Navigator.pop(context, IncomeSourceType.possession),
          ),
        ],
      ),
    );
  }
}

class _SourceTypeTile extends StatelessWidget {
  const _SourceTypeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.lg),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QaydText(
                    title,
                    slot: QaydTextStyleSlot.titleSmall,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
