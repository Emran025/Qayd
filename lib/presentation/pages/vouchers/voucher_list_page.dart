import 'package:flutter/material.dart';
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
import 'package:qayd/presentation/components/atomic/qayd_badge.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_filter_sheet.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_qr_scanner_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';
import 'package:qayd/presentation/widgets/settings_sidebar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/voucher_state_codec.dart';

class VoucherListPage extends StatelessWidget {
  const VoucherListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          VoucherListCubit(InjectionContainer.listVouchersUseCase)..load(),
      child: const _VoucherListView(),
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
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => VoucherDetailCubit(
            InjectionContainer.getVoucherDetailsUseCase,
            InjectionContainer.confirmVoucherUseCase,
          )..load(voucherId),
          child: const VoucherDetailPage(),
        ),
      ),
    );
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
        builder: (ctx) => const VoucherQrScannerPage(),
      ),
    );

    if (data != null && context.mounted) {
      final phone = data['counterpartyPhone'] as String?;
      if (phone != null && phone.isNotEmpty) {
        final findResult = await InjectionContainer.findAccountByPhoneUseCase
            .call(phone);
        if (findResult.isSuccess) {
          final accId = findResult.valueOrNull!;
          data['counterpartyAccountId'] = accId;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يوجد حساب مرتبط برقم الهاتف في الرمز. تم رفض السند.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'الرمز لا يحتوي على رقم هاتف لمعرفة الحساب. تم رفض السند.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
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
          label: Text(
            '${AppStringsAr.voucherFilterChipSearchPrefix}$q',
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
                ? AppStringsAr.voucherTypeReceipt
                : AppStringsAr.voucherTypePayment,
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
      final df = DateFormat.yMMMd('ar');
      final from = f.fromDate != null ? df.format(f.fromDate!) : '…';
      final to = f.toDate != null ? df.format(f.toDate!) : '…';
      chips.add(
        InputChip(
          label: Text('$from — $to'),
          onDeleted: () => cubit.patchAdvancedFilter((x) => x.clearDateRange()),
        ),
      );
    }
    final cp = f.counterpartyAccountId?.trim();
    if (cp != null && cp.isNotEmpty) {
      final name = cubit.accountNamesById[cp] ?? cp;
      chips.add(
        InputChip(
          label: Text(
            '${AppStringsAr.voucherCounterpartyLabel}: $name',
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
          label: Text(
            '${AppStringsAr.voucherAffectedAccountLabel}: $name',
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
          label: Text(AppStringsAr.voucherClearAllFiltersChip),
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
      VoucherState.draft => AppStringsAr.voucherStateDraft,
      VoucherState.confirmed => AppStringsAr.voucherStateConfirmed,
      VoucherState.settled => AppStringsAr.voucherStateSettled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      drawer: const SettingsSidebar(),
      appBar: AppBar(
        title: QaydText(
          AppStringsAr.voucherListTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: AppStringsAr.qrScannerTitle,
            onPressed: () => _scanQr(context),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          IconButton(
            tooltip: AppStringsAr.voucherFilterSheetTitle,
            onPressed: () => _openFilterSheet(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          // const SettingsAppBarAction(),
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
                  gold.withValues(alpha: 0.85),
                  gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_voucher_list',
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStringsAr.voucherNewTitle),
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
            child: ListenableBuilder(
              listenable: _searchController,
              builder: (context, _) {
                return QaydTextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  hint: AppStringsAr.voucherSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
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
              final showChips =
                  cubit.searchQuery.trim().isNotEmpty ||
                  cubit.advancedFilter.hasAny;
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
                        const SizedBox(width: SpacingTokens.xs),
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
                  VoucherListLoading() => const Center(
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
                          const SizedBox(height: SpacingTokens.md),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.read<VoucherListCubit>().load(),
                            child: Text(AppStringsAr.retryAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VoucherListReady(:final vouchers, :final hasActiveQuery) =>
                    vouchers.isEmpty
                        ? Center(
                            child: QaydText(
                              hasActiveQuery
                                  ? AppStringsAr.vouchersEmptyFiltered
                                  : AppStringsAr.vouchersEmpty,
                              slot: QaydTextStyleSlot.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
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
  const _VoucherTile({required this.dto, required this.onTap});

  final VoucherSummaryDto dto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReceipt = dto.typeCode == 'receipt';
    final icon = isReceipt
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final iconBg = isReceipt
        ? ColorTokens.emerald600.withValues(alpha: 0.2)
        : ColorTokens.goldAccent.withValues(alpha: 0.22);
    final iconFg = isReceipt ? ColorTokens.emerald700 : ColorTokens.navy900;

    final dateStr = DateFormat.yMMMd('ar').format(DateTime.parse(dto.dateIso));

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
                    backgroundColor: iconBg,
                    foregroundColor: iconFg,
                    child: Icon(icon, size: 22),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: SpacingTokens.xs,
                          runSpacing: SpacingTokens.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            QaydText(
                              isReceipt
                                  ? AppStringsAr.voucherTypeReceipt
                                  : AppStringsAr.voucherTypePayment,
                              slot: QaydTextStyleSlot.labelLarge,
                            ),
                            QaydBadge(
                              state: voucherStateFromCode(dto.stateCode),
                              context: context,
                            ),
                            QaydBadge.agreement(
                              status: AgreementStatus.values.byName(
                                dto.agreementStatusCode,
                              ),
                              context: context,
                            ),
                            if (dto.isTripartite)
                              Tooltip(
                                message: AppStringsAr.tripartiteBridgeTooltip,
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
                                child: Text(
                                  AppStringsAr.tripartiteContingentBadge,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                            const SizedBox(width: SpacingTokens.md),
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
