import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/groups/currency_settings_page.dart';
import 'package:qayd/core/result/result.dart';

/// The two types of intermediary transfer available.
enum TransferType {
  /// Classic tripartite: A→C→B bridge. The fund is NOT affected.
  tripartite,

  /// Dual-entry with fund: creates two standard vouchers through the cashbox.
  /// The fund IS affected and appears in conversations.
  dualWithFund,
}

/// Bottom sheet that lets the user pick between tripartite and dual transfer.
Future<TransferType?> showTransferTypeSheet(BuildContext context) {
  return showModalBottomSheet<TransferType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => const _TransferTypeBody(),
  );
}

class _TransferTypeBody extends StatelessWidget {
  const _TransferTypeBody();

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
            AppStrings.chooseTheConversionType,
            slot: QaydTextStyleSlot.titleLarge,
          ),
          SizedBox(height: SpacingTokens.xs),
          QaydText(
            AppStrings.selectTheAppropriateTransfer,
            slot: QaydTextStyleSlot.bodySmall,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(height: SpacingTokens.lg),
          _TransferTypeTile(
            icon: Icons.account_tree_rounded,
            color: ColorTokens.emerald500,
            title: AppStrings.intermediateConversionTriple,
            subtitle:
                AppStrings.aBridgeBetweenSender,
            onTap: () async {
              final activeFee =
                  await InjectionContainer.getActiveTransactionFeeUseCase();
              if (activeFee.isSuccess && activeFee.valueOrNull != null) {
                if (context.mounted) {
                  Navigator.pop(context, TransferType.tripartite);
                }
              } else {
                if (context.mounted) {
                  QaydDialog.show(
                    context: context,
                    icon: Icons.settings_suggest_outlined,
                    iconColor: ColorTokens.goldAccent,
                    title: AppStrings.tripartiteDisabledDialogTitle,
                    content: AppStrings.tripartiteDisabledDialogContent,
                    secondaryActionLabel: AppStrings.actionCancel,
                    primaryActionLabel: AppStrings.tripartiteGoToSettings,
                    onPrimaryAction: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.of(context).push(
                        QaydPageRoute.slideFromStart(
                          builder: (ctx) => const CurrencySettingsPage(),
                        ),
                      );
                    },
                  );
                }
              }
            },
          ),
          SizedBox(height: SpacingTokens.sm),
          _TransferTypeTile(
            icon: Icons.swap_horiz_rounded,
            color: ColorTokens.debitBlue,
            title: AppStrings.doubleConversionWithBox,
            subtitle:
                AppStrings.twoOrdinaryBondsAffect,
            onTap: () => Navigator.pop(context, TransferType.dualWithFund),
          ),
        ],
      ),
    );
  }
}

class _TransferTypeTile extends StatelessWidget {
  const _TransferTypeTile({
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
