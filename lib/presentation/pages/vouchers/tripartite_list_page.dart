import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/tripartite_transfer_summary_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/presentation/components/atomic/qayd_badge.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_filter_sheet.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_create_page.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_list_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_qr_scanner_page.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_list_state.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class TripartiteListPage extends StatelessWidget {
  const TripartiteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TripartiteListCubit(InjectionContainer.listVouchersUseCase)..load(),
      child: const _TripartiteListView(),
    );
  }
}

class _TripartiteListView extends StatefulWidget {
  const _TripartiteListView();

  @override
  State<_TripartiteListView> createState() => _TripartiteListViewState();
}

class _TripartiteListViewState extends State<_TripartiteListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate(
    BuildContext context, {
    Map<String, dynamic>? initialData,
  }) async {
    await Navigator.of(context).push<String?>(
      QaydPageRoute.slideFromStart<String?>(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider<VoucherCreateCubit>(
              create: (_) => VoucherCreateCubit(
                InjectionContainer.createVoucherUseCase,
                InjectionContainer.createTripartiteTransferUseCase,
              ),
            ),
          ],
          child: TripartiteCreatePage(initialQrData: initialData),
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TripartiteListCubit>().load();
  }

  Future<void> _scanQr(BuildContext context) async {
    final data = await Navigator.of(context).push<Map<String, dynamic>?>(
      QaydPageRoute.slideFromStart<Map<String, dynamic>?>(
        builder: (ctx) => const VoucherQrScannerPage(),
      ),
    );

    if (data != null && context.mounted) {
      // We can logic here if the QR data is meant for tripartite or standard.
      // For now, let's just pass it to the tripartite create page.
      await _openCreate(context, initialData: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return QaydScaffold(
      appBar: QaydAppBar(
        showNotifications: true,
        title: AppStringsAr.navTripartiteTab,
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_tripartite_list',
        onPressed: () => _openCreate(context),
        label: const Text('تحويل جديد'),
        icon: const Icon(Icons.add_rounded),
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
                  hint: 'بحث بتفاصيل التحويل...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<TripartiteListCubit>().clearSearch();
                          },
                        ),
                  onChanged: (t) {
                    context.read<TripartiteListCubit>().setSearchText(t);
                  },
                );
              },
            ),
          ),
          BlocBuilder<TripartiteListCubit, TripartiteListState>(
            builder: (context, state) {
              final cubit = context.read<TripartiteListCubit>();
              final showChips = state is TripartiteListReady &&
                  (state.searchQuery.trim().isNotEmpty ||
                      state.advancedFilter.hasAny);
              if (!showChips) {
                return const SizedBox.shrink();
              }
              final chipWidgets = _filterChips(context, cubit, state);
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
            child: BlocBuilder<TripartiteListCubit, TripartiteListState>(
              builder: (context, state) {
                if (state is TripartiteListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TripartiteListFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QaydText(
                            state.failure.messageAr,
                            slot: QaydTextStyleSlot.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: SpacingTokens.md),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.read<TripartiteListCubit>().load(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is TripartiteListReady) {
                  if (state.transfers.isEmpty) {
                    final hasQueryOrFilter =
                        state.searchQuery.trim().isNotEmpty ||
                            state.advancedFilter.hasAny;

                    return Center(
                      child: QaydText(
                        hasQueryOrFilter
                            ? 'لا توجد تحويلات مطابقة للبحث.'
                            : 'لا توجد تحويلات وسيطة بعد.',
                        slot: QaydTextStyleSlot.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<TripartiteListCubit>().load(),
                    color: gold,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        SpacingTokens.md,
                        SpacingTokens.sm,
                        SpacingTokens.md,
                        SpacingTokens.xxl * 2,
                      ),
                      itemCount: state.transfers.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: SpacingTokens.sm),
                          child: _TransferSummaryCard(
                              transfer: state.transfers[i]),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final cubit = context.read<TripartiteListCubit>();
    final s = cubit.state;
    if (s is! TripartiteListReady) return;
    final next = await showVoucherAdvancedFilterSheet(
      context,
      initial: s.advancedFilter,
      accountNamesById: s.accountNamesById,
      listAccounts: InjectionContainer.listAccountsUseCase,
    );
    if (next != null && context.mounted) {
      cubit.setAdvancedFilter(next);
    }
  }

  List<Widget> _filterChips(
    BuildContext context,
    TripartiteListCubit cubit,
    TripartiteListReady state,
  ) {
    final chips = <Widget>[];
    final q = state.searchQuery.trim();
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
    final f = state.advancedFilter;
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
      final name = state.accountNamesById[cp] ?? cp;
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
      final name = state.accountNamesById[aff] ?? aff;
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
      VoucherState.withdrawn => AppStringsAr.voucherStateWithdrawn,
    };
  }
}

class _TransferSummaryCard extends StatelessWidget {
  const _TransferSummaryCard({required this.transfer});

  final TripartiteTransferSummaryDto transfer;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final date = DateTime.parse(transfer.dateIso);
    final dateStr = DateFormat.yMMMd('ar').format(date);

    // Check if the transfer is still pending
    final isPending = transfer.receiptVoucher?.receiverStatusCode !=
            AgreementStatus.accepted.name ||
        transfer.paymentVoucher?.receiverStatusCode !=
            AgreementStatus.accepted.name;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isPending
              ? ColorTokens.warningAmber.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final startId =
              transfer.receiptVoucher?.id ?? transfer.paymentVoucher?.id;
          if (startId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('التحويل الوسيط يتم معاينته من خلال سنداته.'),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: gold.withValues(alpha: 0.15),
                foregroundColor: gold,
                child: const Icon(Icons.swap_horiz_rounded, size: 22),
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
                          'تحويل وسيط',
                          slot: QaydTextStyleSlot.labelLarge,
                        ),
                        if (isPending)
                          QaydBadge.agreement(
                            status: AgreementStatus.underRequest,
                            context: context,
                          )
                        else
                          QaydBadge.agreement(
                            status: AgreementStatus.accepted,
                            context: context,
                          ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    // Compact Flow
                    _buildFlowStep(
                      context,
                      transfer.sourceName,
                      Icons.arrow_back_rounded,
                      gold,
                    ),
                    _buildFlowStep(
                      context,
                      transfer.affectedName,
                      Icons.account_balance_wallet_rounded,
                      Theme.of(context).colorScheme.primary,
                      isSecondary: true,
                    ),
                    _buildFlowStep(
                      context,
                      transfer.destinationName,
                      Icons.arrow_forward_rounded,
                      gold,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: QaydText(
                            dateStr,
                            slot: QaydTextStyleSlot.bodySmall,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        QaydMoneyDisplay(
                          money: Money.nonNegative(
                            transfer.amountMinorUnits,
                            CurrencyCode(
                              code: transfer.currencyCode,
                              nameAr: transfer.currencyNameAr,
                              symbol: transfer.currencySymbol,
                              fractionalDigits: transfer.currencyDigits,
                            ),
                          ),
                          size: QaydMoneyDisplaySize.medium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowStep(
    BuildContext context,
    String name,
    IconData icon,
    Color color, {
    bool isSecondary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: QaydText(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              slot: isSecondary
                  ? QaydTextStyleSlot.bodySmall
                  : QaydTextStyleSlot.titleSmall,
              color: isSecondary ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
