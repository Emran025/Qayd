import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/accounts/account_create_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_create_page.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_page.dart';
import 'package:qayd/presentation/pages/accounts/account_list_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_list_grouping.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_list_state.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AccountListCubit(InjectionContainer.listAccountsUseCase)..load(),
      child: const _AccountListScaffold(),
    );
  }
}

class _AccountListScaffold extends StatefulWidget {
  const _AccountListScaffold();

  @override
  State<_AccountListScaffold> createState() => _AccountListScaffoldState();
}

class _AccountListScaffoldState extends State<_AccountListScaffold> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate({
    String? parentId,
    String? parentName,
    String? parentStandardKind,
    bool isChild = false,
  }) async {
    final created = await Navigator.of(context).push<bool>(
      QaydPageRoute.slideFromStart<bool>(
        builder: (ctx) => BlocProvider(
          create: (_) =>
              AccountCreateCubit(InjectionContainer.createAccountUseCase),
          child: AccountCreatePage(
            parentAccountId: parentId,
            parentName: parentName,
            parentStandardKind: parentStandardKind,
            forcedIsChild: isChild,
            allowedStandardKinds: const [
              StandardAccountClassificationKind.liquidAssets,
              StandardAccountClassificationKind.receivables,
              StandardAccountClassificationKind.payables,
              StandardAccountClassificationKind.settlements,
            ],
          ),
        ),
      ),
    );
    if (created == true && mounted) {
      await context.read<AccountListCubit>().load();
    }
  }

  Future<void> _openDetail(String accountId) async {
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) =>
              AccountDetailCubit(InjectionContainer.getAccountDetailsUseCase)
                ..load(accountId),
          child: const AccountDetailPage(),
        ),
      ),
    );
  }

  Future<void> _openChat(String accountId) async {
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            counterpartyAccountId: accountId,
          )..load(),
          child: AccountStatementChatPage(counterpartyAccountId: accountId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return QaydScaffold(
      appBar: QaydAppBar(
        showNotifications: true,
        title: AppStringsAr.chartOfAccountsTitle,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_account_list',
        onPressed: () {
          final state = context.read<AccountListCubit>().state;
          if (state is AccountListReady) {
            final isChild = state.typeFilter == AccountTypeFilter.child;
            _openCreate(isChild: isChild);
          } else {
            _openCreate();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStringsAr.addAccountFab),
        backgroundColor: gold,
        foregroundColor: ColorTokens.navy950,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.sm,
              SpacingTokens.md,
              SpacingTokens.xs,
            ),
            child: QaydTextField(
              controller: _searchController,
              hint: AppStringsAr.searchAccountsHint,
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (q) =>
                  context.read<AccountListCubit>().setSearchQuery(q),
            ),
          ),
          BlocBuilder<AccountListCubit, AccountListState>(
            builder: (context, state) {
              final ready = state is AccountListReady;
              final natureFilter =
                  ready ? state.natureFilter : AccountNatureFilter.all;
              final typeFilter =
                  ready ? state.typeFilter : AccountTypeFilter.child;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.xs,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Wrap(
                        spacing: SpacingTokens.sm,
                        children: [
                          ChoiceChip(
                            label: Text(AppStringsAr.filterNatureAll),
                            selected: natureFilter == AccountNatureFilter.all,
                            onSelected: (_) => context
                                .read<AccountListCubit>()
                                .setNatureFilter(AccountNatureFilter.all),
                          ),
                          ChoiceChip(
                            label: Text(AppStringsAr.filterNatureDebit),
                            selected: natureFilter == AccountNatureFilter.debit,
                            onSelected: (_) => context
                                .read<AccountListCubit>()
                                .setNatureFilter(AccountNatureFilter.debit),
                          ),
                          ChoiceChip(
                            label: Text(AppStringsAr.filterNatureCredit),
                            selected:
                                natureFilter == AccountNatureFilter.credit,
                            onSelected: (_) => context
                                .read<AccountListCubit>()
                                .setNatureFilter(AccountNatureFilter.credit),
                          ),
                        ],
                      ),
                      const SizedBox.shrink(),
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      SegmentedButton<AccountTypeFilter>(
                        segments: const [
                          ButtonSegment(
                            value: AccountTypeFilter.child,
                            label: Text(AppStringsAr.accountTypeChild),
                          ),
                          ButtonSegment(
                            value: AccountTypeFilter.root,
                            label: Text(AppStringsAr.accountTypeRoot),
                          ),
                        ],
                        selected: {typeFilter},
                        onSelectionChanged: (s) => context
                            .read<AccountListCubit>()
                            .setTypeFilter(s.first),
                        showSelectedIcon: false,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<AccountListCubit, AccountListState>(
              builder: (context, state) {
                return switch (state) {
                  AccountListInitial() => const SizedBox.shrink(),
                  AccountListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  AccountListFailure(:final failure) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QaydText(
                              failure.messageAr,
                              slot: QaydTextStyleSlot.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            FilledButton.tonal(
                              onPressed: () =>
                                  context.read<AccountListCubit>().load(),
                              child: Text(AppStringsAr.retryAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AccountListReady(
                    :final allAccounts,
                    :final filteredAccounts,
                  ) =>
                    _AccountListBody(
                      accounts: filteredAccounts,
                      chartIsEmpty: allAccounts.isEmpty,
                      onTap: _openDetail,
                      onChat: _openChat,
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountListBody extends StatelessWidget {
  const _AccountListBody({
    required this.accounts,
    required this.chartIsEmpty,
    required this.onTap,
    required this.onChat,
  });

  final List<AccountSummaryDto> accounts;
  final bool chartIsEmpty;
  final void Function(String accountId) onTap;
  final void Function(String accountId) onChat;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Center(
        child: QaydText(
          chartIsEmpty
              ? AppStringsAr.accountsEmpty
              : AppStringsAr.accountsEmptyFiltered,
          slot: QaydTextStyleSlot.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final sections = buildAccountSections(accounts);
    final flat = _flatten(sections);
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: SpacingTokens.md,
        right: SpacingTokens.md,
        bottom: SpacingTokens.xxl,
      ),
      itemCount: flat.length,
      itemBuilder: (context, index) {
        final item = flat[index];
        return switch (item) {
          _HeaderRow(:final title) => Padding(
              padding: const EdgeInsets.only(
                top: SpacingTokens.md,
                bottom: SpacingTokens.sm,
              ),
              child: QaydText(
                title,
                slot: QaydTextStyleSlot.titleMedium,
                color: Theme.of(
                  context,
                ).extension<QaydCustomColors>()!.goldAccent,
              ),
            ),
          _DataRow(:final dto) => _AccountCard(
              dto: dto,
              onTap: () => onChat(dto.id),
              onChat: () => onChat(dto.id),
            ),
        };
      },
    );
  }
}

sealed class _FlatItem {}

final class _HeaderRow extends _FlatItem {
  _HeaderRow(this.title);

  final String title;
}

final class _DataRow extends _FlatItem {
  _DataRow(this.dto);

  final AccountSummaryDto dto;
}

List<_FlatItem> _flatten(
  List<({String key, String title, List<AccountSummaryDto> rows})> sections,
) {
  final out = <_FlatItem>[];
  for (final s in sections) {
    out.add(_HeaderRow(s.title));
    for (final r in s.rows) {
      out.add(_DataRow(r));
    }
  }
  return out;
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.dto,
    required this.onTap,
    required this.onChat,
  });

  final AccountSummaryDto dto;
  final VoidCallback onTap;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final natureDebit = dto.natureCode == 'debit';
    final natureColor = natureDebit ? custom.debit : custom.credit;
    final natureLabel = natureDebit
        ? AppStringsAr.natureDebitShort
        : AppStringsAr.natureCreditShort;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: dto.isRoot ? 0 : SpacingTokens.md,
                              ),
                              child: QaydText(
                                dto.name,
                                slot: QaydTextStyleSlot.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: natureColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  RadiusTokens.xs,
                                ),
                                border: Border.all(
                                  color: natureColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: QaydText(
                                natureLabel,
                                slot: QaydTextStyleSlot.labelSmall,
                                color: natureColor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: AppStringsAr.statementChatTitle,
                            icon: Icon(
                              Icons.forum_outlined,
                              size: 22,
                              color: custom.debit.withValues(alpha: 0.8),
                            ),
                            onPressed: onChat,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (dto.balancesMinorUnits.isNotEmpty) ...[
                    const SizedBox(height: SpacingTokens.sm),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: SpacingTokens.sm),
                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(), // Currency
                        1: FlexColumnWidth(), // Amount
                        2: IntrinsicColumnWidth(), // Side
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: dto.balancesMinorUnits.entries.map((e) {
                        final code = e.key;
                        final minor = e.value;

                        // Side determination:
                        // For Debit accounts: positive = Debit, negative = Credit
                        // For Credit accounts: positive = Credit, negative = Debit
                        final isDebitSide =
                            (dto.natureCode == 'debit' && minor >= 0) ||
                                (dto.natureCode == 'credit' && minor < 0);

                        final sideLabel = isDebitSide
                            ? AppStringsAr.natureDebitShort
                            : AppStringsAr.natureCreditShort;
                        final sideColor =
                            isDebitSide ? custom.debit : custom.credit;

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: QaydText(
                                code,
                                slot: QaydTextStyleSlot.labelMedium,
                                color: scheme.onSurfaceVariant,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.md,
                              ),
                              child: QaydMoneyDisplay(
                                money: Money.nonNegative(
                                  minor.abs(),
                                  PredefinedCurrencies.all.firstWhere(
                                    (c) => c.code == code,
                                    orElse: () => CurrencyCode(
                                      code: code,
                                      nameAr: code,
                                      symbol: code,
                                    ),
                                  ),
                                ),
                                displayNegative:
                                    false, // Handled by Side column
                                size: QaydMoneyDisplaySize.small,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: SpacingTokens.md,
                              ),
                              child: QaydText(
                                sideLabel,
                                slot: QaydTextStyleSlot.labelSmall,
                                color: sideColor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: SpacingTokens.sm),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: QaydMoneyDisplay(
                        money: Money.zero(PredefinedCurrencies.sar),
                        size: QaydMoneyDisplaySize.small,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
