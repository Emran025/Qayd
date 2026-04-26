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
import 'package:qayd/presentation/pages/accounts/archived_accounts_page.dart';
import 'package:qayd/presentation/pages/accounts/archived_accounts_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class AccountListPage extends StatefulWidget {
  const AccountListPage(
      {super.key, this.isRootMode = false, this.isActive = true});
  final bool isRootMode;
  final bool isActive;

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  late final AccountListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AccountListCubit(InjectionContainer.listAccountsUseCase,
        initialTypeFilter: widget.isRootMode
            ? AccountTypeFilter.root
            : AccountTypeFilter.child)
      ..load();
  }

  @override
  void didUpdateWidget(AccountListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _cubit.load();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _AccountListScaffold(isRootMode: widget.isRootMode),
    );
  }
}

class _AccountListScaffold extends StatefulWidget {
  const _AccountListScaffold({required this.isRootMode});
  final bool isRootMode;

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
    if (mounted) {
      context.read<AccountListCubit>().load();
    }
  }

  Future<void> _openChat(String accountId) async {
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
              listStatement: InjectionContainer.listAccountStatementChatUseCase,
              listAccounts: InjectionContainer.listAccountsUseCase,
              counterpartyAccountId: accountId,
              getCostCenterDetails:
                  InjectionContainer.getCostCenterDetailsUseCase)
            ..load(),
          child: AccountStatementChatPage(counterpartyAccountId: accountId),
        ),
      ),
    );
    if (mounted) {
      context.read<AccountListCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return QaydScaffold(
      appBar: QaydAppBar(
        showNotifications: true,
        title: widget.isRootMode
            ? AppStringsAr.chartOfAccountsTitle
            : AppStringsAr.navAccountsTab,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: AppStringsAr.archivedAccountsTitle,
            onPressed: () async {
              await Navigator.of(context).push<void>(
                QaydPageRoute.slideFromStart<void>(
                  builder: (ctx) => BlocProvider(
                    create: (_) => ArchivedAccountsCubit(
                      listArchivedAccounts:
                          InjectionContainer.listArchivedAccountsUseCase,
                      restoreAccount: InjectionContainer.restoreAccountUseCase,
                    )..load(),
                    child: const ArchivedAccountsPage(),
                  ),
                ),
              );
              if (context.mounted) {
                context.read<AccountListCubit>().load();
              }
            },
          ),
        ],
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
        return (item is _DataRow)
            ? _AccountCard(
                key: ValueKey(item.dto.id),
                dto: item.dto,
                onDetail: () => onTap(item.dto.id),
                onChat: () => onChat(item.dto.id),
              )
            : Center();
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
    super.key,
    required this.dto,
    required this.onDetail,
    required this.onChat,
  });

  final AccountSummaryDto dto;
  final VoidCallback onDetail;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final natureDebit = dto.natureCode == 'debit';
    final natureColor = natureDebit ? custom.debit : custom.credit;
    final iconData = _getAccountIcon(dto.standardClassificationKind);

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          boxShadow: [
            BoxShadow(
              color: natureColor.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
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
              // ── Top Accent Line ──
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      natureColor.withValues(alpha: 0.8),
                      natureColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
              // ── Card Body ──
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    left: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    right: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onChat,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SpacingTokens.sm,
                        10,
                        SpacingTokens.sm,
                        SpacingTokens.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header Row ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon Avatar
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  borderRadius:
                                      BorderRadius.circular(RadiusTokens.md),
                                ),
                                child: Icon(
                                  iconData,
                                  size: 18,
                                  color: natureColor,
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.sm),
                              // Name & Classification
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    QaydText(
                                      dto.name,
                                      slot: QaydTextStyleSlot.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Classification label
                                    QaydText(
                                      _getClassificationLabel(dto),
                                      slot: QaydTextStyleSlot.labelSmall,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.sm),
                              // Detail navigation button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onDetail,
                                  borderRadius:
                                      BorderRadius.circular(RadiusTokens.sm),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: scheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          RadiusTokens.sm),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 13,
                                      color: scheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Balance Section ──
                          if (dto.balancesMinorUnits.isNotEmpty) ...[
                            const SizedBox(height: SpacingTokens.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.md,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.sm),
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                children: _buildBalanceRows(
                                  dto,
                                  custom,
                                  scheme,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBalanceRows(
    AccountSummaryDto dto,
    QaydCustomColors custom,
    ColorScheme scheme,
  ) {
    final entries = dto.balancesMinorUnits.entries.toList();
    final widgets = <Widget>[];

    for (var i = 0; i < entries.length; i++) {
      final code = entries[i].key;
      final minor = entries[i].value;

      final isDebitSide = (dto.natureCode == 'debit' && minor >= 0) ||
          (dto.natureCode == 'credit' && minor < 0);

      final String sideLabel;
      final Color sideColor;

      if (minor == 0) {
        sideLabel = AppStringsAr.statementBalanceSettled;
        sideColor = custom.credit;
      } else {
        sideLabel = isDebitSide
            ? AppStringsAr.natureDebitShort
            : AppStringsAr.natureCreditShort;
        sideColor = isDebitSide ? custom.credit : custom.debit;
      }

      // Row separator (between rows only)
      if (i > 0) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Currency code
              QaydText(
                code,
                slot: QaydTextStyleSlot.labelSmall,
                style: const TextStyle(fontWeight: FontWeight.w600),
                color: scheme.onSurfaceVariant,
              ),
              const Spacer(),
              // Money amount
              QaydMoneyDisplay(
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
                displayNegative: false,
                size: QaydMoneyDisplaySize.small,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(width: 6),
              // Side label badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: sideColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RadiusTokens.xs),
                  border: Border.all(
                    color: sideColor.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: QaydText(
                  sideLabel,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: sideColor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

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
}
