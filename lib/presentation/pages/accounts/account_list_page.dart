import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/accounts/account_create_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_create_page.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_page.dart';
import 'package:qayd/presentation/pages/accounts/account_list_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_list_grouping.dart';
import 'package:qayd/presentation/pages/settings/settings_app_bar_action.dart';
import 'package:qayd/presentation/pages/accounts/account_list_state.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

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

  Future<void> _openCreate({String? parentId, String? parentName}) async {
    final created = await Navigator.of(context).push<bool>(
      QaydPageRoute.slideFromStart<bool>(
        builder: (ctx) => BlocProvider(
          create: (_) => AccountCreateCubit(
            InjectionContainer.createAccountUseCase,
          ),
          child: AccountCreatePage(
            parentAccountId: parentId,
            parentName: parentName,
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
          create: (_) => AccountDetailCubit(
            InjectionContainer.getAccountDetailsUseCase,
          )..load(accountId),
          child: const AccountDetailPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      appBar: AppBar(
        title: QaydText(
          AppStringsAr.chartOfAccountsTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        actions: const [
          SettingsAppBarAction(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  gold.withValues(alpha: 0.9),
                  gold.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(),
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
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                hintText: AppStringsAr.searchAccountsHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              onChanged: (q) =>
                  context.read<AccountListCubit>().setSearchQuery(q),
            ),
          ),
          BlocBuilder<AccountListCubit, AccountListState>(
            builder: (context, state) {
              final filter = state is AccountListReady
                  ? state.natureFilter
                  : AccountNatureFilter.all;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.xs,
                ),
                child: Wrap(
                  spacing: SpacingTokens.sm,
                  children: [
                    ChoiceChip(
                      label: Text(AppStringsAr.filterNatureAll),
                      selected: filter == AccountNatureFilter.all,
                      onSelected: (_) => context
                          .read<AccountListCubit>()
                          .setNatureFilter(AccountNatureFilter.all),
                    ),
                    ChoiceChip(
                      label: Text(AppStringsAr.filterNatureDebit),
                      selected: filter == AccountNatureFilter.debit,
                      onSelected: (_) => context
                          .read<AccountListCubit>()
                          .setNatureFilter(AccountNatureFilter.debit),
                    ),
                    ChoiceChip(
                      label: Text(AppStringsAr.filterNatureCredit),
                      selected: filter == AccountNatureFilter.credit,
                      onSelected: (_) => context
                          .read<AccountListCubit>()
                          .setNatureFilter(AccountNatureFilter.credit),
                    ),
                  ],
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
                      onAddChild: (dto) => _openCreate(
                        parentId: dto.id,
                        parentName: dto.name,
                      ),
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
    required this.onAddChild,
  });

  final List<AccountSummaryDto> accounts;
  final bool chartIsEmpty;
  final void Function(String accountId) onTap;
  final void Function(AccountSummaryDto dto) onAddChild;

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
                color: Theme.of(context).extension<QaydCustomColors>()!.goldAccent,
              ),
            ),
          _DataRow(:final dto) => _AccountCard(
              dto: dto,
              onTap: () => onTap(dto.id),
              onAddChild: () => onAddChild(dto),
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
    required this.onAddChild,
  });

  final AccountSummaryDto dto;
  final VoidCallback onTap;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final natureDebit = dto.natureCode == 'debit';
    final natureColor = natureDebit ? custom.debit : custom.credit;
    final natureLabel =
        natureDebit ? AppStringsAr.natureDebitShort : AppStringsAr.natureCreditShort;

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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: natureColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: QaydText(
                                natureLabel,
                                slot: QaydTextStyleSlot.labelSmall,
                                color: natureColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ...dto.balancesMinorUnits.entries.map((e) {
                            final code = e.key;
                            final minor = e.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  QaydText(
                                    code,
                                    slot: QaydTextStyleSlot.labelSmall,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  QaydMoneyDisplay(
                                    money: Money.nonNegative(
                                        minor.abs(),
                                        PredefinedCurrencies.all.firstWhere(
                                            (c) => c.code == code,
                                            orElse: () => CurrencyCode(
                                                code: code,
                                                nameAr: code,
                                                symbol: code))),
                                    displayNegative: minor < 0,
                                    size: QaydMoneyDisplaySize.small,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          if (dto.balancesMinorUnits.isEmpty)
                            QaydMoneyDisplay(
                              money: Money.zero(PredefinedCurrencies.sar),
                              size: QaydMoneyDisplaySize.small,
                            ),
                        ],
                      ),
                      IconButton(
                        tooltip: AppStringsAr.addChildAccountTooltip,
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: custom.goldAccent,
                        ),
                        onPressed: onAddChild,
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
