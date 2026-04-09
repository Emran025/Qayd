import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_cubit.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_mode.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_page.dart';
import 'package:qayd/presentation/utils/account_statement_pdf_export.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountDetailCubit, AccountDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: QaydAppBar(
            title: state is AccountDetailReady
                ? state.data.name
                : AppStringsAr.accountDetailTitle,
            actions: [
              if (state is AccountDetailReady) ...[
                IconButton(
                  tooltip: AppStringsAr.accountSendMessageTooltip,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      QaydPageRoute.slideFromStart<void>(
                        builder: (ctx) => NotificationPreviewPage(
                          mode:
                              NotificationPreviewAccount(state.data.accountId),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'محادثة كشف الحساب',
                  icon: const Icon(Icons.forum_outlined),
                  onPressed: () => Navigator.of(context).push<void>(
                    QaydPageRoute.slideFromStart<void>(
                      builder: (ctx) => BlocProvider(
                        create: (_) => StatementChatCubit(
                          listStatement: InjectionContainer
                              .listAccountStatementChatUseCase,
                          listAccounts: InjectionContainer.listAccountsUseCase,
                          counterpartyAccountId: state.data.accountId,
                        )..load(),
                        child: AccountStatementChatPage(
                          counterpartyAccountId: state.data.accountId,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStringsAr.accountStatementExportPdfTooltip,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => shareAccountStatementAsPdf(
                    context,
                    accountId: state.data.accountId,
                  ),
                ),
                IconButton(
                  tooltip: AppStringsAr.refreshBalanceTooltip,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => context
                      .read<AccountDetailCubit>()
                      .load(state.data.accountId),
                ),
              ],
            ],
          ),
          body: switch (state) {
            AccountDetailInitial() || AccountDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            AccountDetailFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: QaydText(
                    failure.messageAr,
                    slot: QaydTextStyleSlot.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            AccountDetailReady(:final data) => _DetailBody(data: data),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data});

  final GetAccountDetailsOutput data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final created =
        DateFormat.yMMMd('ar').format(DateTime.parse(data.createdAtIso));

    final classificationText = data.standardClassificationKind != null
        ? AppStringsAr.standardClassificationLabel(
            data.standardClassificationKind!)
        : data.customClassificationName ?? AppStringsAr.classificationOther;

    final natureDebit = data.natureCode == 'debit';
    final natureColor = natureDebit ? custom.debit : custom.credit;
    final natureLabel = natureDebit
        ? AppStringsAr.natureDebitShort
        : AppStringsAr.natureCreditShort;

    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QaydText(
                  AppStringsAr.accountBalanceLabel,
                  slot: QaydTextStyleSlot.labelMedium,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: SpacingTokens.xs),
                ...data.balancesMinorUnits.entries.map((e) {
                  final code = e.key;
                  final minor = e.value;
                  // For simplicity in UI, we fetch the symbol from PredefinedCurrencies
                  // or fallback to the code itself.

                  return Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QaydText(
                          code,
                          slot: QaydTextStyleSlot.bodySmall,
                          color: scheme.onSurfaceVariant,
                        ),
                        QaydMoneyDisplay(
                          money: Money.nonNegative(
                              minor.abs(),
                              PredefinedCurrencies.all.firstWhere(
                                  (c) => c.code == code,
                                  orElse: () => CurrencyCode(
                                      code: code, nameAr: code, symbol: code))),
                          displayNegative: minor < 0,
                          size: data.balancesMinorUnits.length > 1
                              ? QaydMoneyDisplaySize.medium
                              : QaydMoneyDisplaySize.large,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (data.balancesMinorUnits.isEmpty)
                  QaydText(
                    '---',
                    slot: QaydTextStyleSlot.titleMedium,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        _MetaRow(
          label: AppStringsAr.classificationLabel,
          value: classificationText,
        ),
        _MetaRow(
          label: AppStringsAr.natureLabel,
          value: natureLabel,
          valueColor: natureColor,
        ),
        _MetaRow(
          label: AppStringsAr.accountTypeLabel,
          value: data.isRoot
              ? AppStringsAr.accountTypeRoot
              : AppStringsAr.accountTypeChild,
        ),
        if (data.parentId != null)
          _MetaRow(
            label: AppStringsAr.parentAccountLabel,
            value: data.parentName ?? data.parentId!,
          ),
        _MetaRow(
          label: AppStringsAr.statusLabel,
          value: data.isActive
              ? AppStringsAr.statusActive
              : AppStringsAr.statusInactive,
        ),
        _MetaRow(
          label: AppStringsAr.createdAtLabel,
          value: created,
        ),
        if (data.phoneNumber != null ||
            data.whatsappNumber != null ||
            data.bankAccountInfo != null ||
            data.partyType != null) ...[
          const SizedBox(height: SpacingTokens.lg),
          QaydText(
            AppStringsAr.partyDetailsSection,
            slot: QaydTextStyleSlot.titleMedium,
            color: scheme.primary,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.partyType?.isNotEmpty == true)
                    _MetaRow(
                        label: AppStringsAr.partyTypeLabel,
                        value: data.partyType!),
                  if (data.phoneNumber?.isNotEmpty == true)
                    _ActionRow(
                      icon: Icons.phone,
                      label: data.phoneNumber!,
                      actionLabel: AppStringsAr.actionCall,
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${data.phoneNumber}')),
                    ),
                  if (data.whatsappNumber?.isNotEmpty == true)
                    _ActionRow(
                      icon: Icons.message_rounded,
                      label: data.whatsappNumber!,
                      actionLabel: AppStringsAr.actionWhatsApp,
                      onTap: () => launchUrl(
                          Uri.parse('https://wa.me/${data.whatsappNumber}')),
                    ),
                  if (data.bankAccountInfo?.isNotEmpty == true)
                    _ActionRow(
                      icon: Icons.account_balance_rounded,
                      label: data.bankAccountInfo!,
                      actionLabel: AppStringsAr.actionCopyBank,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: data.bankAccountInfo!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(AppStringsAr.bankInfoCopied)),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: QaydText(
              label,
              slot: QaydTextStyleSlot.bodyMedium,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            flex: 3,
            child: QaydText(
              value,
              slot: QaydTextStyleSlot.bodyLarge,
              color: valueColor,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: QaydText(
              label,
              slot: QaydTextStyleSlot.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
