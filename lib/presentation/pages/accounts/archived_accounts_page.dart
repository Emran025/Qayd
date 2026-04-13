import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/accounts/archived_accounts_cubit.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/account_archive_helper.dart';

class ArchivedAccountsPage extends StatelessWidget {
  const ArchivedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QaydAppBar(title: AppStringsAr.archivedAccountsTitle),
      body: BlocBuilder<ArchivedAccountsCubit, ArchivedAccountsState>(
        builder: (context, state) {
          if (state is ArchivedAccountsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ArchivedAccountsFailure) {
            return Center(child: Text(state.failure.messageAr));
          }
          if (state is ArchivedAccountsReady) {
            final accounts = state.data.accounts;
            if (accounts.isEmpty) {
              return const Center(
                child: QaydText(AppStringsAr.archivedAccountsEmpty,
                    slot: QaydTextStyleSlot.bodyLarge),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(SpacingTokens.md),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                return _ArchivedAccountCard(account: accounts[index]);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ArchivedAccountCard extends StatelessWidget {
  const _ArchivedAccountCard({required this.account});

  final AccountSummaryDto account;

  IconData _getAccountIcon(String? kind) {
    if (kind == null) return Icons.account_balance_wallet_rounded;
    return switch (kind) {
      'liquidAssets' => Icons.account_balance_rounded,
      'receivables' => Icons.trending_up_rounded,
      'payables' => Icons.trending_down_rounded,
      'settlements' => Icons.handshake_rounded,
      'equity' => Icons.pie_chart_rounded,
      'revenues' => Icons.monetization_on_rounded,
      'expenses' => Icons.receipt_long_rounded,
      _ => Icons.folder_rounded,
    };
  }

  String _getClassificationLabel(AccountSummaryDto dto) {
    final nature = dto.natureCode == 'debit'
        ? AppStringsAr.natureDebitShort
        : AppStringsAr.natureCreditShort;

    if (dto.customClassificationName != null) {
      return '${dto.customClassificationName} • $nature';
    }
    return nature;
  }

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final natureDebit = account.natureCode == 'debit';
    final natureColor = natureDebit ? custom.debit : custom.credit;
    final iconData = _getAccountIcon(account.standardClassificationKind);

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          boxShadow: [
            BoxShadow(
              color: natureColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vibrant Top Accent Line matching active accounts
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      natureColor.withValues(alpha: 0.7),
                      natureColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              // Card Body
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    left: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    right: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SpacingTokens.sm,
                    12,
                    SpacingTokens.sm,
                    12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Colored Icon Avatar matching active accounts
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                          border: Border.all(
                            color: natureColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Icon(
                          iconData,
                          size: 20,
                          color: natureColor.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      // Text Segment without strikethrough
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            QaydText(
                              account.name,
                              slot: QaydTextStyleSlot.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            QaydText(
                              _getClassificationLabel(account),
                              slot: QaydTextStyleSlot.labelSmall,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      // Restore action (matching detail navigation button)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => confirmAndRestoreAccount(
                              context, account.id, account.name),
                          borderRadius: BorderRadius.circular(RadiusTokens.sm),
                          child: Tooltip(
                            message: AppStringsAr.restoreAccountAction,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.sm),
                              ),
                              child: Icon(
                                Icons.unarchive_outlined,
                                size: 18,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
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
