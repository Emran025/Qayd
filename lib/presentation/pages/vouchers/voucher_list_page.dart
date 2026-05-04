import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_floating_action_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_empty_state.dart';
import 'package:qayd/presentation/components/atomic/qayd_badge.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_filter_sheet.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_qr_scanner_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/conflict_banner.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/voucher_state_codec.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

class VoucherListPage extends StatefulWidget {
  const VoucherListPage({super.key, this.isActive = true});
  final bool isActive;

  @override
  State<VoucherListPage> createState() => _VoucherListPageState();
}

class _VoucherListPageState extends State<VoucherListPage> {
  late final VoucherListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = VoucherListCubit(
      InjectionContainer.listVouchersUseCase,
      InjectionContainer.notificationMessageRepository,
      isInternalOnly: false,
    )..load();
  }

  @override
  void didUpdateWidget(VoucherListPage oldWidget) {
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
      child: _VoucherListView(),
    );
  }
}

class _VoucherListView extends StatefulWidget {
  const _VoucherListView();

  @override
  State<_VoucherListView> createState() => _VoucherListViewState();
}

class _VoucherListViewState extends State<_VoucherListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetail(BuildContext context, String voucherId) async {
    await VoucherDetailPage.show(context, voucherId);
    if (context.mounted) {
      await context.read<VoucherListCubit>().load();
    }
  }

  Future<void> _openCreate(BuildContext context) async {
    final newId = await Navigator.of(context).push<String?>(
      QaydPageRoute.slideFromStart<String?>(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider<VoucherCreateCubit>(
              create: (_) => VoucherCreateCubit(
                InjectionContainer.createVoucherUseCase,
                InjectionContainer.createTripartiteTransferUseCase,
              ),
            ),
            BlocProvider<VoucherSuggestionsCubit>(
              create: (_) => VoucherSuggestionsCubit(
                InjectionContainer.getAutoSuggestionsUseCase,
                InjectionContainer.markNotificationMessageProcessedUseCase,
              ),
            ),
          ],
          child: const VoucherCreatePage(),
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<VoucherListCubit>().load();
    if (newId != null && context.mounted) {
      await _openDetail(context, newId);
    }
  }

  Future<void> _scanQr(BuildContext context) async {
    final data = await Navigator.of(context).push<Map<String, dynamic>?>(
      QaydPageRoute.slideFromStart<Map<String, dynamic>?>(
        builder: (ctx) => VoucherQrScannerPage(),
      ),
    );

    if (data != null && context.mounted) {
      final phone = (data['counterpartyPhone'] ?? data['signerPhone']) as String?;
      if (phone != null && phone.isNotEmpty) {
        final findResult =
            await InjectionContainer.findAccountByPhoneUseCase.call(phone);
        final accId = findResult.valueOrNull;
        if (findResult.isSuccess && accId != null) {
          data['counterpartyAccountId'] = accId;
        } else {
          final counterpartyName = data['counterpartyName'] as String? ?? phone;
          final confirmed = await QaydDialog.show<bool>(
            context: context,
            icon: Icons.person_add_rounded,
            title: AppStrings.thereIsNoAccount,
            content:
                '${AppStrings.theCodeDoesNot} ($counterpartyName). ${AppStrings.confirmSelection}؟',
            primaryActionLabel: AppStrings.confirmSelection,
            secondaryActionLabel: AppStrings.actionCancel,
            onPrimaryAction: () => Navigator.of(context).pop(true),
          );

          if (confirmed == true && context.mounted) {
            // Find a suitable parent (Receivables)
            final rootsR = await InjectionContainer.listAccountsUseCase
                .call(const ListAccountsInput(activeOnly: true));
            final receivablesRoot = rootsR.valueOrNull?.accounts
                .where((a) =>
                    a.isRoot &&
                    a.standardClassificationKind ==
                        StandardAccountClassificationKind.receivables.name)
                .firstOrNull;

            final createResult =
                await InjectionContainer.createAccountUseCase.call(
              CreateAccountInput(
                name: counterpartyName,
                phoneNumber: phone,
                parentAccountId: receivablesRoot?.id,
                rootStandardKind: receivablesRoot == null
                    ? StandardAccountClassificationKind.receivables
                    : null,
              ),
            );

            if (createResult.isSuccess) {
              data['counterpartyAccountId'] =
                  createResult.valueOrNull!.accountId;
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(createResult.failureOrNull!.messageAr)),
                );
              }
              return;
            }
          } else {
            return;
          }
        }
      } else if (data['receiptUuid'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.theCodeDoesNot,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Smart Navigation: If this QR belongs to an existing voucher, go to Detail directly.
      final existingId = data['receiptUuid'] as String?;
      if (existingId != null) {
        final check = await InjectionContainer.voucherRepository
            .getById(VoucherId(existingId));
        if (check.isSuccess) {
          if (context.mounted) {
            await _openDetail(context, existingId);
          }
          return;
        }
      }

      final newId = await Navigator.of(context).push<String?>(
        QaydPageRoute.slideFromStart<String?>(
          builder: (ctx) => MultiBlocProvider(
            providers: [
              BlocProvider<VoucherCreateCubit>(
                create: (_) => VoucherCreateCubit(
                  InjectionContainer.createVoucherUseCase,
                  InjectionContainer.createTripartiteTransferUseCase,
                ),
              ),
              BlocProvider<VoucherSuggestionsCubit>(
                create: (_) => VoucherSuggestionsCubit(
                  InjectionContainer.getAutoSuggestionsUseCase,
                  InjectionContainer.markNotificationMessageProcessedUseCase,
                ),
              ),
            ],
            child: VoucherCreatePage(initialQrData: data),
          ),
        ),
      );
      if (newId != null && context.mounted) {
        await context.read<VoucherListCubit>().load();
        await _openDetail(context, newId);
      }
    }
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final cubit = context.read<VoucherListCubit>();
    final next = await showVoucherAdvancedFilterSheet(
      context,
      initial: cubit.advancedFilter,
      accountNamesById: cubit.accountNamesById,
      listAccounts: InjectionContainer.listAccountsUseCase,
    );
    if (next != null && context.mounted) {
      cubit.setAdvancedFilter(next);
    }
  }

  List<Widget> _filterChips(BuildContext context, VoucherListCubit cubit) {
    final chips = <Widget>[];
    final q = cubit.searchQuery.trim();
    if (q.isNotEmpty) {
      chips.add(
        InputChip(
          label: QaydText(
            '${AppStrings.voucherFilterChipSearchPrefix}$q',
            slot: QaydTextStyleSlot.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () {
            _searchController.clear();
            cubit.clearSearch();
          },
        ),
      );
    }
    final f = cubit.advancedFilter;
    if (f.type != null) {
      chips.add(
        InputChip(
          label: Text(
            f.type == VoucherType.receipt
                ? AppStrings.voucherTypeReceipt
                : AppStrings.voucherTypePayment,
          ),
          onDeleted: () => cubit.patchAdvancedFilter((x) => x.clearType()),
        ),
      );
    }
    if (f.state != null) {
      chips.add(
        InputChip(
          label: Text(_stateLabel(f.state!)),
          onDeleted: () => cubit.patchAdvancedFilter((x) => x.clearState()),
        ),
      );
    }
    if (f.fromDate != null || f.toDate != null) {
      final df = DateFormat.yMMMd(AppStrings.languageCode);
      final from = f.fromDate != null ? df.format(f.fromDate!) : '…';
      final to = f.toDate != null ? df.format(f.toDate!) : '…';
      chips.add(
        InputChip(
          label: QaydText(
            '$from — $to',
            slot: QaydTextStyleSlot.labelMedium,
          ),
          onDeleted: () => cubit.patchAdvancedFilter((x) => x.clearDateRange()),
        ),
      );
    }
    final cp = f.counterpartyAccountId?.trim();
    if (cp != null && cp.isNotEmpty) {
      final name = cubit.accountNamesById[cp] ?? cp;
      chips.add(
        InputChip(
          label: QaydText(
            '${AppStrings.voucherCounterpartyLabel}: $name',
            slot: QaydTextStyleSlot.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () =>
              cubit.patchAdvancedFilter((x) => x.clearCounterparty()),
        ),
      );
    }
    final aff = f.affectedAccountId?.trim();
    if (aff != null && aff.isNotEmpty) {
      final name = cubit.accountNamesById[aff] ?? aff;
      chips.add(
        InputChip(
          label: QaydText(
            '${AppStrings.voucherAffectedAccountLabel}: $name',
            slot: QaydTextStyleSlot.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () => cubit.patchAdvancedFilter((x) => x.clearAffected()),
        ),
      );
    }
    if (chips.isNotEmpty) {
      chips.add(
        ActionChip(
          label: Text(AppStrings.voucherClearAllFiltersChip),
          onPressed: () {
            _searchController.clear();
            cubit.clearAllFiltersAndSearch();
          },
        ),
      );
    }
    return chips;
  }

  String _stateLabel(VoucherState s) {
    return switch (s) {
      VoucherState.draft => AppStrings.voucherStateDraft,
      VoucherState.confirmed => AppStrings.voucherStateConfirmed,
      VoucherState.settled => AppStrings.voucherStateSettled,
      VoucherState.withdrawn => AppStrings.voucherStateWithdrawn,
    };
  }

  @override
  Widget build(BuildContext context) {
    return QaydScaffold(
      appBar: QaydAppBar(
        showNotifications: true,
        title: AppStrings.voucherListTitle,
        actions: [
          IconButton(
            tooltip: AppStrings.qrScannerTitle,
            onPressed: () => _scanQr(context),
            icon: Icon(Icons.qr_code_scanner_rounded),
          ),
          IconButton(
            tooltip: AppStrings.voucherFilterSheetTitle,
            onPressed: () => _openFilterSheet(context),
            icon: Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: QaydFloatingActionButton.extended(
        heroTag: 'fab_voucher_list',
        onPressed: () => _openCreate(context),
        icon: Icon(Icons.add_rounded),
        label: Text(AppStrings.voucherNewTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<VoucherListCubit, VoucherListState>(
            builder: (context, state) {
              if (state is VoucherListReady &&
                  state.mergeProposals.isNotEmpty) {
                return ConflictBanner(proposals: state.mergeProposals);
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.sm,
              SpacingTokens.md,
              SpacingTokens.xs,
            ),
            child: ListenableBuilder(
              listenable: _searchController,
              builder: (context, _) {
                return QaydTextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  hint: AppStrings.voucherSearchHint,
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<VoucherListCubit>().clearSearch();
                          },
                        ),
                  onChanged: (t) {
                    context.read<VoucherListCubit>().setSearchText(t);
                  },
                );
              },
            ),
          ),
          BlocBuilder<VoucherListCubit, VoucherListState>(
            builder: (context, state) {
              final cubit = context.read<VoucherListCubit>();
              final showChips = cubit.searchQuery.trim().isNotEmpty ||
                  cubit.advancedFilter.hasDisplayableFilters;
              if (!showChips) {
                return const SizedBox.shrink();
              }
              final chipWidgets = _filterChips(context, cubit);
              return Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                    ),
                    itemCount: chipWidgets.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: SpacingTokens.xs),
                    itemBuilder: (_, i) => chipWidgets[i],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<VoucherListCubit, VoucherListState>(
              builder: (context, state) {
                return switch (state) {
                  VoucherListInitial() => const SizedBox.shrink(),
                  VoucherListLoading() => Center(
                      child: CircularProgressIndicator(),
                    ),
                  VoucherListFailure(:final failure) => Center(
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
                            SizedBox(height: SpacingTokens.md),
                            FilledButton.tonal(
                              onPressed: () =>
                                  context.read<VoucherListCubit>().load(),
                              child: Text(AppStrings.retryAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                  VoucherListReady(:final vouchers, :final hasActiveQuery) =>
                    vouchers.isEmpty
                        ? QaydEmptyState(
                            icon: hasActiveQuery
                                ? Icons.search_off_rounded
                                : Icons.receipt_long_outlined,
                            title: hasActiveQuery
                                ? AppStrings.vouchersEmptyFiltered
                                : AppStrings.vouchersEmpty,
                            description: hasActiveQuery
                                ? AppStrings.tryChangingTheFilters
                                : AppStrings.startByAddingYour,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              SpacingTokens.md,
                              SpacingTokens.sm,
                              SpacingTokens.md,
                              SpacingTokens.xxl,
                            ),
                            itemCount: vouchers.length,
                            itemBuilder: (context, i) {
                              return _VoucherTile(
                                dto: vouchers[i],
                                onTap: () =>
                                    _openDetail(context, vouchers[i].id),
                                onOriginTap: vouchers[i].originVoucherId != null
                                    ? () => _openDetail(
                                        context, vouchers[i].originVoucherId!)
                                    : null,
                                onChildTap: vouchers[i].firstChildId != null
                                    ? () => _openDetail(
                                        context, vouchers[i].firstChildId!)
                                    : null,
                              );
                            },
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

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({
    required this.dto,
    required this.onTap,
    this.onOriginTap,
    this.onChildTap,
  });

  final VoucherSummaryDto dto;
  final VoidCallback onTap;
  final VoidCallback? onOriginTap;
  final VoidCallback? onChildTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReceipt = dto.typeCode == 'receipt';
    final icon =
        isReceipt ? Icons.south_west_rounded : Icons.north_east_rounded;
    final dateStr = DateFormat.yMMMd(AppStrings.languageCode)
        .format(DateTime.parse(dto.dateIso));

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isReceipt
                        ? ColorTokens.emerald600.withValues(alpha: 0.2)
                        : ColorTokens.goldAccent.withValues(alpha: 0.22),
                    foregroundColor: isReceipt
                        ? ColorTokens.emerald700
                        : ColorTokens.navy900,
                    child: Icon(icon, size: 22),
                  ),
                  SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dto.originVoucherId != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: SpacingTokens.xs),
                            child: InkWell(
                              onTap: onOriginTap,
                              child: Row(
                                children: [
                                  Icon(Icons.reply_rounded,
                                      size: 14, color: scheme.primary),
                                  SizedBox(width: SpacingTokens.xs),
                                  Expanded(
                                    child: Text(
                                      AppStrings.voucherReplyHeader,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Wrap(
                          spacing: SpacingTokens.xs,
                          runSpacing: SpacingTokens.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            QaydText(
                              isReceipt
                                  ? AppStrings.voucherTypeReceipt
                                  : AppStrings.voucherTypePayment,
                              slot: QaydTextStyleSlot.labelLarge,
                            ),
                            QaydBadge(
                              state: voucherStateFromCode(dto.stateCode),
                              context: context,
                            ),
                            QaydBadge.agreement(
                              status: AgreementStatus.values.byName(
                                dto.receiverStatusCode,
                              ),
                              context: context,
                            ),
                            if (dto.isTripartite)
                              Tooltip(
                                message: AppStrings.tripartiteBridgeTooltip,
                                child: Icon(
                                  Icons
                                      .account_tree_outlined, // Bridge/tree icon
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).extension<QaydCustomColors>()!.goldAccent,
                                ),
                              ),
                            if (dto.isContingent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: QaydText(
                                  AppStrings.tripartiteContingentBadge,
                                  slot: QaydTextStyleSlot.labelSmall,
                                  // fontWeight: FontWeight.bold,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            if (dto.hasCollateral)
                              Tooltip(
                                message: AppStrings.voucherCollateralSection,
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ),
                            // ── Transaction Markers (Protocol §3.3) ─────────
                            if (dto.reversalCount > 0)
                              ActionChip(
                                padding: EdgeInsets.zero,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                avatar: Icon(Icons.history_rounded, size: 12),
                                label: QaydText(
                                  '${AppStrings.voucherReversalIndicator} ${dto.reversalCount}',
                                  slot: QaydTextStyleSlot.labelSmall,
                                ),
                                onPressed: onChildTap,
                              ),
                            if (dto.stateCode == 'settled')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ColorTokens.emerald600
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: QaydText(
                                  AppStrings.voucherSettlementIndicator,
                                  slot: QaydTextStyleSlot.labelSmall,
                                  // fontWeight: FontWeight.bold,
                                  color: ColorTokens.emerald700,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: QaydText(
                                dto.counterpartyName,
                                slot: QaydTextStyleSlot.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SpacingTokens.md),
                            QaydMoneyDisplay(
                              money: Money.nonNegative(
                                dto.amountMinorUnits,
                                CurrencyCode(
                                  code: dto.currencyCode,
                                  nameAr: dto.currencyNameAr,
                                  symbol: dto.currencySymbol,
                                  fractionalDigits: dto.currencyDigits,
                                ),
                              ),
                              size: QaydMoneyDisplaySize.medium,
                            ),
                          ],
                        ),
                        QaydText(
                          dateStr,
                          slot: QaydTextStyleSlot.bodySmall,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
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
