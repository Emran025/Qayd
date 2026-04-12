import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qayd/application/accounts/dtos/account_statement_chat_message_dto.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_badge.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/atomic/qayd_snackbar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_filter_sheet.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_state.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/widgets/request_tripartite_sheet.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';
import 'package:qayd/presentation/utils/statement_chat_export.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';

/// Chat-style "Statement of Account" between two parties (accounts).
///
/// Full implementation with:
/// - BLoC-powered state management
/// - Search bar with debounce
/// - Advanced filtering (agreement status, type, date range, brought-forward)
/// - Color-coded bubbles (Green/Blue/Orange/Red)
/// - Running balance on each bubble
/// - Summary footer with net balance
/// - Accept / Reject / Resubmit interactive actions
final class AccountStatementChatPage extends StatefulWidget {
  const AccountStatementChatPage({
    super.key,
    required this.counterpartyAccountId,
    this.myAccountId,
  });

  final String counterpartyAccountId;
  final String? myAccountId;

  @override
  State<AccountStatementChatPage> createState() =>
      _AccountStatementChatPageState();
}

class _AccountStatementChatPageState extends State<AccountStatementChatPage> {
  bool _mutating = false;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Actions ──

  Future<void> _acceptVoucher(BuildContext context, String voucherId) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      final r = await InjectionContainer.confirmVoucherUseCase.call(
        ConfirmVoucherInput(voucherId: voucherId),
      );
      if (r.isFailure && mounted) {
        QaydSnackBar.show(
          context,
          r.failureOrNull!.messageAr,
          type: QaydSnackBarType.error,
        );
        return;
      }
      if (mounted) {
        QaydSnackBar.show(
          context,
          AppStringsAr.voucherAcceptedSuccess,
          type: QaydSnackBarType.success,
        );
        context.read<StatementChatCubit>().reload();
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _rejectVoucher(BuildContext context, String voucherId) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      final r = await InjectionContainer.rejectVoucherUseCase.call(
        voucherId: voucherId,
      );
      if (r.isFailure && mounted) {
        QaydSnackBar.show(
          context,
          r.failureOrNull!.messageAr,
          type: QaydSnackBarType.error,
        );
        return;
      }
      if (mounted) {
        QaydSnackBar.show(
          context,
          AppStringsAr.voucherRejectedSuccess,
          type: QaydSnackBarType.success,
        );
        context.read<StatementChatCubit>().reload();
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _resubmitVoucher(BuildContext context, String voucherId) async {
    // Instead of resubmit usecase, we now navigate to create page to allow edits
    // as per Protocol v1.4 (Corrective Resubmission).
    final cubit = context.read<StatementChatCubit>();
    final state = cubit.state;
    if (state is! StatementChatReady) return;

    final msg = state.messages.firstWhere((m) => m.voucherId == voucherId);

    Navigator.of(context)
        .push(
          QaydPageRoute.slideFromStart(
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
              child: VoucherCreatePage(
                initialQrData: {
                  'type': msg.typeCode == 'payment'
                      ? VoucherType.payment
                      : VoucherType.receipt,
                  'date': DateTime.parse(msg.dateIso),
                  'amountMinorUnits': msg.amountMinorUnits,
                  'description': msg.description,
                  'counterpartyAccountId': msg.otherPartyId,
                  'originVoucherId': msg.voucherId,
                },
              ),
            ),
          ),
        )
        .then((_) => cubit.reload());
  }

  Future<void> _withdrawVoucher(BuildContext context, String voucherId) async {
    final cubit = context.read<StatementChatCubit>();
    final state = cubit.state;
    if (state is! StatementChatReady) return;
    final msg = state.messages.firstWhere((m) => m.voucherId == voucherId);

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.voucherWithdrawConfirmTitle),
        content: Text(AppStringsAr.voucherWithdrawConfirmBody),
        actions: [
          // 1. Cancel
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          // 2. Withdraw/Delete
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'withdraw'),
            child: Text(AppStringsAr.voucherDeleteOrWithdraw),
          ),
          // 3. Redirect
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'edit_others'),
            child: Text(AppStringsAr.voucherRedirectToOthers),
          ),
        ],
      ),
    );

    if (action == 'withdraw') {
      setState(() => _mutating = true);
      final result = await InjectionContainer.withdrawVoucherUseCase.call(
        voucherId: voucherId,
      );
      setState(() => _mutating = false);

      result.fold(
        (f) => QaydSnackBar.show(context, f.messageAr,
            type: QaydSnackBarType.error),
        (_) {
          QaydSnackBar.show(context, AppStringsAr.voucherWithdrawalSuccess,
              type: QaydSnackBarType.success);
          cubit.reload();
        },
      );
    } else if (action == 'edit_others') {
      Navigator.of(context)
          .push(
            QaydPageRoute.slideFromStart(
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
                      InjectionContainer
                          .markNotificationMessageProcessedUseCase,
                    ),
                  ),
                ],
                child: VoucherCreatePage(
                  initialQrData: {
                    'type': msg.typeCode == 'payment'
                        ? VoucherType.payment
                        : VoucherType.receipt,
                    'date': DateTime.parse(msg.dateIso),
                    'amountMinorUnits': msg.amountMinorUnits,
                    'description': msg.description,
                    'counterpartyAccountId': msg.otherPartyId,
                    'originVoucherId': msg.voucherId,
                  },
                ),
              ),
            ),
          )
          .then((_) => cubit.reload());
    }
  }

  Future<void> _openAccountProfile(String accountId) async {
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

  Future<void> _navigateToCounterpartyChat(
    BuildContext context,
    String cpAccountId,
    String myAccountId,
  ) async {
    // Navigate to the individual chat with that specific party
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            counterpartyAccountId: cpAccountId,
            myAccountId: myAccountId,
          )..load(),
          child: AccountStatementChatPage(
            counterpartyAccountId: cpAccountId,
            myAccountId: myAccountId,
          ),
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(StatementChatCubit cubit) async {
    final result = await showStatementChatFilterSheet(
      context,
      initial: cubit.filter,
    );
    if (result != null && mounted) {
      cubit.setFilter(result);
    }
  }

  void _showVoucherActions(
    BuildContext context,
    AccountStatementChatMessageDto msg,
  ) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.lg),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: custom.subtleBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(RadiusTokens.pill),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),

            // Interaction buttons like "same movement of reaction buttons"
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
              child: Row(
                children: [
                  if (msg.isCreator &&
                      msg.signatureStatusCode == AgreementStatus.rejected.name)
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      label: AppStringsAr.voucherEditAction,
                      onTap: () {
                        Navigator.pop(ctx);
                        _resubmitVoucher(context, msg.voucherId);
                      },
                    ),
                  if (msg.isCreator &&
                      !AgreementStatus.values
                          .byName(msg.signatureStatusCode)
                          .isAccepted)
                    _ActionButton(
                      icon: Icons.undo_rounded,
                      label: AppStringsAr.statementChatWithdraw,
                      color: ColorTokens.errorDeep,
                      onTap: () {
                        Navigator.pop(ctx);
                        _withdrawVoucher(context, msg.voucherId);
                      },
                    ),
                  _ActionButton(
                    icon: Icons.description_outlined,
                    label: AppStringsAr.actionDetails,
                    onTap: () {
                      Navigator.pop(ctx);
                      VoucherDetailPage.show(context, msg.voucherId);
                    },
                  ),
                  if (msg.mediatorAccountId != null)
                    _ActionButton(
                      icon: Icons.support_agent_rounded,
                      label: AppStringsAr.tripartiteMediatorLabel,
                      color: custom.goldAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateToCounterpartyChat(
                          context,
                          msg.mediatorAccountId!,
                          widget.myAccountId ?? widget.counterpartyAccountId,
                        );
                      },
                    ),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    label: AppStringsAr.actionCopy,
                    onTap: () {
                      Navigator.pop(ctx);
                      // Add copy logic
                    },
                  ),
                  _ActionButton(
                    icon: Icons.share_rounded,
                    label: AppStringsAr.actionShare,
                    onTap: () {
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<List<_BalanceSnapshot>> _calculateAllRollingSnapshots(
    List<AccountStatementChatMessageDto> history,
    int initialBalanceForPrimary,
  ) {
    final List<List<_BalanceSnapshot>> snapshotsList = [];
    final Map<String, _BalanceSnapshot> currentBalances = {};

    if (history.isNotEmpty) {
      final first = history.first;
      currentBalances[first.currencyCode] = _BalanceSnapshot(
        code: first.currencyCode,
        symbol: first.currencySymbol,
        digits: first.currencyDigits,
        amount: initialBalanceForPrimary,
      );
    }

    for (final m in history) {
      final current = currentBalances[m.currencyCode] ??
          _BalanceSnapshot(
            code: m.currencyCode,
            symbol: m.currencySymbol,
            digits: m.currencyDigits,
            amount: 0,
          );

      if (m.signatureStatusCode != AgreementStatus.rejected.name) {
        int impact = m.amountMinorUnits;
        if (m.direction == 'outgoing') impact = -impact;

        currentBalances[m.currencyCode] = current.copyWith(
          amount: current.amount + impact,
        );
      }
      snapshotsList.add(currentBalances.values.toList());
    }

    return snapshotsList;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatementChatCubit, StatementChatState>(
      builder: (context, state) {
        if (state is StatementChatInitial || state is StatementChatLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is StatementChatFailure) {
          return Scaffold(
            body: Center(
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
                    FilledButton(
                      onPressed: () =>
                          context.read<StatementChatCubit>().load(),
                      child: Text(AppStringsAr.retryAction),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = state as StatementChatReady;
        final cubit = context.read<StatementChatCubit>();
        final custom = Theme.of(context).extension<QaydCustomColors>()!;

        final int firstUnreadIndex = data.messages.indexWhere(
          (m) =>
              m.direction == 'incoming' &&
              m.signatureStatusCode == 'underRequest',
        );

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding:
                const EdgeInsets.only(bottom: 40.0), // Lift it a bit higher
            child: FloatingActionButton.extended(
              onPressed: () {
                RequestTripartiteSheet.show(
                  context,
                  destinationAccountId: data.counterpartyAccountId,
                  destinationName: data.counterpartyName,
                );
              },
              // Swap positions: Text on right, Icon on left (in RTL)
              icon: null,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStringsAr.tripartiteRequestFunds),
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded),
                ],
              ),
              backgroundColor: custom.goldAccent,
              foregroundColor: ColorTokens.navy950,
            ),
          ),
          body: Column(
            children: [
              // ── Header ──
              _ChatHeader(
                counterpartyName: data.counterpartyName,
                counterpartyAccountId: data.counterpartyAccountId,
                messageCount: data.messages.length,
                hasFilters: data.hasActiveFilters,
                showSearch: _showSearch,
                isUnified: data.isUnified,
                onProfileTap: () =>
                    _openAccountProfile(data.counterpartyAccountId),
                onSearchToggle: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      cubit.clearSearch();
                    }
                  });
                },
                onFilterTap: () => _openFilterSheet(cubit),
                onExportPdf: () => shareStatementChatAsPdf(
                  context,
                  accountId: data.counterpartyAccountId,
                  accountName: data.counterpartyName,
                  filter: data.filter,
                  messages: data.messages,
                  broughtForwardMinorUnits: data.broughtForwardMinorUnits,
                ),
                onExportExcel: () => shareStatementChatAsExcel(
                  context,
                  accountId: data.counterpartyAccountId,
                  accountName: data.counterpartyName,
                  filter: data.filter,
                  messages: data.messages,
                  broughtForwardMinorUnits: data.broughtForwardMinorUnits,
                  currencyDigits: data.currencyDigits,
                ),
              ),

              // ── Search bar ──
              if (_showSearch)
                _SearchBar(
                  controller: _searchController,
                  onChanged: (text) => cubit.setSearchText(text),
                  onClear: () {
                    _searchController.clear();
                    cubit.clearSearch();
                  },
                ),

              // ── Filter chips ──
              if (data.hasActiveFilters)
                _ActiveFilterChips(
                  data: data,
                  onClearAll: () {
                    _searchController.clear();
                    cubit.clearAllFiltersAndSearch();
                  },
                ),

              // ── View Mode Toggle ──
              _ViewModeToggle(
                mode: data.filter.viewMode,
                onChanged: (m) => cubit.setViewMode(m),
              ),

              // ── Brought Forward Balance card ──
              if (data.broughtForwardMinorUnits != 0 &&
                  data.filter.includePreviousBalance)
                _BroughtForwardCard(
                  balanceMinorUnits: data.broughtForwardMinorUnits,
                  currencySymbol: data.currencySymbol,
                  currencyDigits: data.currencyDigits,
                ),

              // ── Messages list ──
              Expanded(
                child: data.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(SpacingTokens.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 56,
                                color: custom.subtleBorder,
                              ),
                              const SizedBox(height: SpacingTokens.md),
                              QaydText(
                                data.hasActiveFilters
                                    ? AppStringsAr.statementChatEmptyFiltered
                                    : AppStringsAr.statementChatEmpty,
                                slot: QaydTextStyleSlot.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => cubit.reload(),
                        child: Builder(
                          builder: (context) {
                            // Pre-calculate all chronology snapshots in one go (O(N))
                            final allSnapshots = _calculateAllRollingSnapshots(
                              data.messages,
                              data.broughtForwardMinorUnits,
                            );

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                left: SpacingTokens.sm,
                                right: SpacingTokens.sm,
                                top: SpacingTokens.sm,
                                bottom:
                                    110.0, // Extra padding so FAB doesn't cover numbers
                              ),
                              itemCount: data.messages.length,
                              itemBuilder: (context, i) {
                                final msg = data.messages[i];
                                final balances = allSnapshots[i];

                                final msgWidget = _MessageBubble(
                                  msg: msg,
                                  mutating: _mutating,
                                  isUnified: data.isUnified,
                                  onAccept: (id) => _acceptVoucher(context, id),
                                  onReject: (id) => _rejectVoucher(context, id),
                                  onWithdraw: (id) =>
                                      _withdrawVoucher(context, id),
                                  onResubmit: (id) =>
                                      _resubmitVoucher(context, id),
                                  onTap: () => data.isUnified
                                      ? _navigateToCounterpartyChat(
                                          context,
                                          msg.otherPartyId,
                                          data.counterpartyAccountId,
                                        )
                                      : VoucherDetailPage.show(
                                          context, msg.voucherId),
                                  onLongPress: () =>
                                      _showVoucherActions(context, msg),
                                );

                                final itemWidget = Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (i == firstUnreadIndex)
                                      const _UnreadSessionDivider(),

                                    msgWidget,

                                    // Centered balance summary table
                                    _ChronologySummaryTable(balances: balances),

                                    const SizedBox(height: SpacingTokens.sm),
                                  ],
                                );

                                return itemWidget;
                              },
                            );
                          },
                        ),
                      ),
              ),

              // ── Summary footer ──
              if (data.messages.isNotEmpty)
                _SummaryFooter(
                  finalBalanceMinorUnits: data.finalBalanceMinorUnits,
                  messageCount: data.messages.length,
                  currencySymbol: data.currencySymbol,
                  currencyDigits: data.currencyDigits,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Chat Header ──────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.counterpartyName,
    required this.counterpartyAccountId,
    required this.messageCount,
    required this.hasFilters,
    required this.showSearch,
    required this.isUnified,
    required this.onProfileTap,
    required this.onSearchToggle,
    required this.onFilterTap,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  final String counterpartyName;
  final String counterpartyAccountId;
  final int messageCount;
  final bool hasFilters;
  final bool showSearch;
  final bool isUnified;
  final VoidCallback onProfileTap;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xs,
            vertical: SpacingTokens.xs,
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'رجوع',
              ),
              // Avatar + Name
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  onTap: onProfileTap,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: custom.debit.withValues(alpha: 0.15),
                        foregroundColor: custom.debit,
                        child: Text(
                          counterpartyName.isNotEmpty
                              ? counterpartyName.trim().substring(0, 1)
                              : '?',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              counterpartyName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isUnified
                                  ? AppStringsAr.statementUnifiedTitle
                                  : '$messageCount ${AppStringsAr.statementVoucherCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search toggle
              IconButton(
                icon: Icon(
                  showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  size: 22,
                ),
                onPressed: onSearchToggle,
              ),
              // Filter
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 22),
                    onPressed: onFilterTap,
                  ),
                  if (hasFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: custom.goldAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              // Options Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                onSelected: (val) {
                  if (val == 'pdf') onExportPdf();
                  if (val == 'excel') onExportExcel();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 20),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(AppStringsAr.accountStatementExportPdfTooltip),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        const Icon(Icons.table_view_outlined, size: 20),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(AppStringsAr.settingsExportStatementTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Search Bar ───────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: AppStringsAr.statementChatSearchHint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Active Filter Chips ──────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.data, required this.onClearAll});

  final StatementChatReady data;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final chips = <Widget>[];

    if (data.searchQuery.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text(
            '${AppStringsAr.voucherFilterChipSearchPrefix}${data.searchQuery}',
          ),
          onDeleted: () => context.read<StatementChatCubit>().clearSearch(),
          deleteIconColor: custom.goldAccent,
        ),
      );
    }

    if (data.filter.agreementStatus != null) {
      final label = switch (data.filter.agreementStatus!) {
        AgreementStatus.accepted => AppStringsAr.statementStatusConfirmed,
        AgreementStatus.underRequest => AppStringsAr.statementStatusPending,
        AgreementStatus.rejected => AppStringsAr.statementStatusRejected,
        AgreementStatus.unverified => AppStringsAr.agreementUnverified,
      };
      chips.add(
        InputChip(
          label: Text(label),
          onDeleted: () {
            final cubit = context.read<StatementChatCubit>();
            cubit.setFilter(cubit.filter.copyWith(clearAgreementStatus: true));
          },
          deleteIconColor: custom.goldAccent,
        ),
      );
    }

    if (data.filter.type != null) {
      final label = data.filter.type == VoucherType.receipt
          ? AppStringsAr.voucherTypeReceipt
          : AppStringsAr.voucherTypePayment;
      chips.add(
        InputChip(
          label: Text(label),
          onDeleted: () {
            final cubit = context.read<StatementChatCubit>();
            cubit.setFilter(cubit.filter.copyWith(clearType: true));
          },
          deleteIconColor: custom.goldAccent,
        ),
      );
    }

    if (data.filter.fromDate != null || data.filter.toDate != null) {
      final df = DateFormat.yMd('en');
      final from =
          data.filter.fromDate != null ? df.format(data.filter.fromDate!) : '…';
      final to =
          data.filter.toDate != null ? df.format(data.filter.toDate!) : '…';
      chips.add(
        InputChip(
          label: Text('$from → $to'),
          onDeleted: () {
            final cubit = context.read<StatementChatCubit>();
            cubit.setFilter(
              cubit.filter.copyWith(clearFromDate: true, clearToDate: true),
            );
          },
          deleteIconColor: custom.goldAccent,
        ),
      );
    }

    chips.add(
      ActionChip(
        label: Text(AppStringsAr.voucherClearAllFiltersChip),
        onPressed: onClearAll,
        avatar: Icon(
          Icons.clear_all_rounded,
          size: 16,
          color: custom.goldAccent,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.xs,
      ),
      child: Wrap(
        spacing: SpacingTokens.sm,
        runSpacing: SpacingTokens.xs,
        children: chips,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Brought Forward Card ─────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _BroughtForwardCard extends StatelessWidget {
  const _BroughtForwardCard({
    required this.balanceMinorUnits,
    required this.currencySymbol,
    required this.currencyDigits,
  });

  final int balanceMinorUnits;
  final String currencySymbol;
  final int currencyDigits;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final isPositive = balanceMinorUnits >= 0;
    final color = isPositive ? custom.credit : ColorTokens.errorDeep;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 20, color: color),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: QaydText(
              AppStringsAr.statementBroughtForward,
              slot: QaydTextStyleSlot.bodyMedium,
            ),
          ),
          _BalanceAmountText(
            minorUnits: balanceMinorUnits,
            currencySymbol: currencySymbol,
            currencyDigits: currencyDigits,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Unread Session Divider ───────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _UnreadSessionDivider extends StatelessWidget {
  const _UnreadSessionDivider();

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: custom.goldAccent.withValues(alpha: 0.5),
              thickness: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: custom.goldAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mark_chat_unread_rounded,
                  size: 14,
                  color: custom.goldAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  AppStringsAr.statementUnreadMessages,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: custom.goldAccent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(
              color: custom.goldAccent.withValues(alpha: 0.5),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Summary Footer ───────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({
    required this.finalBalanceMinorUnits,
    required this.messageCount,
    required this.currencySymbol,
    required this.currencyDigits,
  });

  final int finalBalanceMinorUnits;
  final int messageCount;
  final String currencySymbol;
  final int currencyDigits;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isPositive = finalBalanceMinorUnits > 0;
    final isNegative = finalBalanceMinorUnits < 0;
    final statusLabel = isPositive
        ? AppStringsAr.statementBalanceForYou
        : isNegative
            ? AppStringsAr.statementBalanceAgainstYou
            : AppStringsAr.statementBalanceSettled;
    final statusColor = isPositive
        ? custom.credit
        : isNegative
            ? ColorTokens.errorDeep
            : custom.confirmedState;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: custom.subtleBorder.withValues(alpha: 0.5)),
        ),
      ),
      padding: EdgeInsets.only(
        left: SpacingTokens.md,
        right: SpacingTokens.md,
        top: SpacingTokens.sm + 2,
        bottom: MediaQuery.paddingOf(context).bottom + SpacingTokens.sm + 2,
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStringsAr.statementFinalBalance,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          // Balance amount
          _BalanceAmountText(
            minorUnits: finalBalanceMinorUnits,
            currencySymbol: currencySymbol,
            currencyDigits: currencyDigits,
            large: true,
          ),
        ],
      ),
    );
  }
}

class _BalanceSnapshot {
  const _BalanceSnapshot({
    required this.code,
    required this.symbol,
    required this.digits,
    required this.amount,
  });

  final String code;
  final String symbol;
  final int digits;
  final int amount;

  _BalanceSnapshot copyWith({int? amount}) {
    return _BalanceSnapshot(
      code: code,
      symbol: symbol,
      digits: digits,
      amount: amount ?? this.amount,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectColor = color ?? scheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: effectColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectColor, size: 24),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChronologySummaryTable extends StatelessWidget {
  const _ChronologySummaryTable({required this.balances});

  final List<_BalanceSnapshot> balances;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) return const SizedBox.shrink();

    final custom = Theme.of(context).extension<QaydCustomColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: balances.map((b) {
              final isPositive = b.amount > 0;
              final isNegative = b.amount < 0;
              final color = isPositive
                  ? custom.credit
                  : isNegative
                      ? ColorTokens.errorDeep
                      : custom.confirmedState;

              final label = isPositive
                  ? 'دائن (لك)'
                  : isNegative
                      ? 'مدين (عليك)'
                      : 'متعادل';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _BalanceAmountText(
                      minorUnits: b.amount,
                      currencySymbol: b.symbol,
                      currencyDigits: b.digits,
                      fontSize: 11,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Message Bubble ───────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.msg,
    required this.mutating,
    required this.isUnified,
    required this.onAccept,
    required this.onReject,
    required this.onWithdraw,
    required this.onResubmit,
    required this.onTap,
    required this.onLongPress,
  });

  final AccountStatementChatMessageDto msg;
  final bool mutating;
  final bool isUnified;
  final Future<void> Function(String voucherId) onAccept;
  final Future<void> Function(String voucherId) onReject;
  final Future<void> Function(String voucherId) onWithdraw;
  final Future<void> Function(String voucherId) onResubmit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  bool get _isIncoming => msg.direction == 'incoming';
  bool get _isOutgoing => msg.direction == 'outgoing';

  // ── Color-coded status system ──
  // 🟢 Green  = Confirmed (accepted)
  // 🔵 Blue   = Receipt voucher
  // 🟠 Orange = Pending (underRequest)
  // 🔴 Red    = Rejected

  Color _statusColor(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final agreement = AgreementStatus.values.byName(msg.signatureStatusCode);
    if (agreement.isRejected) return ColorTokens.errorDeep;
    if (agreement.isAccepted) return custom.confirmedState;
    if (msg.typeCode == VoucherType.receipt.name) return custom.debit;
    return custom.draftState;
  }

  String _typeLabel() {
    return msg.typeCode == VoucherType.receipt.name
        ? AppStringsAr.voucherTypeReceipt
        : AppStringsAr.voucherTypePayment;
  }

  IconData _typeIcon() {
    return msg.typeCode == VoucherType.receipt.name
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
  }

  IconData _ticksIcon() {
    final agreement = AgreementStatus.values.byName(msg.signatureStatusCode);
    if (agreement.isRejected) return Icons.close_rounded;
    if (agreement.isAccepted) return Icons.done_all_rounded;
    if (agreement.isUnderRequest) return Icons.check_rounded;
    return Icons.schedule_rounded;
  }

  Widget _stateWidget(BuildContext context) {
    final status = AgreementStatus.values.byName(msg.signatureStatusCode);
    if (status.isRejected) {
      return QaydBadge.agreement(
        status: AgreementStatus.rejected,
        context: context,
      );
    }
    if (status.isAccepted) {
      return QaydBadge.agreement(
        status: AgreementStatus.accepted,
        context: context,
      );
    }
    final state = VoucherState.values.byName(msg.voucherStateCode);
    return QaydBadge(state: state, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd('en').format(DateTime.parse(msg.dateIso));
    final statusColor = _statusColor(context);
    final scheme = Theme.of(context).colorScheme;
    final custom = Theme.of(context).extension<QaydCustomColors>()!;

    final currency = CurrencyCode(
      code: msg.currencyCode,
      nameAr: msg.currencyCode,
      symbol: msg.currencySymbol,
      fractionalDigits: msg.currencyDigits,
    );
    final money = Money.fromMinorUnits(msg.amountMinorUnits, currency);

    final alignment = _isIncoming
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(RadiusTokens.lg),
                topEnd: const Radius.circular(RadiusTokens.lg),
                bottomStart: _isIncoming
                    ? const Radius.circular(RadiusTokens.xs)
                    : const Radius.circular(RadiusTokens.lg),
                bottomEnd: _isOutgoing
                    ? const Radius.circular(RadiusTokens.xs)
                    : const Radius.circular(RadiusTokens.lg),
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Colored accent strip ──
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor,
                          statusColor.withValues(alpha: 0.40),
                        ],
                      ),
                    ),
                  ),

                  // ── Card content ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ──── Header: type + badge + ticks ────
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            SpacingTokens.md,
                            SpacingTokens.sm + 2,
                            SpacingTokens.md,
                            SpacingTokens.sm,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.06),
                            border: Border(
                              bottom: BorderSide(
                                color: statusColor.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Type icon in circle
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _typeIcon(),
                                  size: 14,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.sm),
                              // Type label & Other Party
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _typeLabel(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                    ),
                                    if (isUnified)
                                      Text(
                                        msg.otherPartyName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: statusColor.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              // Badge
                              _stateWidget(context),
                              const SizedBox(width: SpacingTokens.xs),
                              // Ticks
                              Icon(
                                _ticksIcon(),
                                size: 15,
                                color: statusColor.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),

                        // ──── Amount display ────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.md,
                            vertical: SpacingTokens.sm + 2,
                          ),
                          child: Row(
                            children: [
                              // Amount
                              Expanded(
                                child: QaydMoneyDisplay(
                                  money: money,
                                  size: QaydMoneyDisplaySize.large,
                                  displayNegative: false,
                                ),
                              ),
                              // Currency code chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacingTokens.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                    RadiusTokens.xs,
                                  ),
                                ),
                                child: Text(
                                  msg.currencyCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ──── Description ────
                        if (msg.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              SpacingTokens.md,
                              0,
                              SpacingTokens.md,
                              SpacingTokens.sm,
                            ),
                            child: Text(
                              msg.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                            ),
                          ),

                        // ──── Remittance Meta ────
                        if (msg.mediatorName != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              SpacingTokens.md,
                              0,
                              SpacingTokens.md,
                              SpacingTokens.sm,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.tertiaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.sm),
                                border: Border.all(
                                  color: scheme.tertiary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.handshake_rounded,
                                    size: 14,
                                    color: scheme.tertiary,
                                  ),
                                  const SizedBox(width: SpacingTokens.xs),
                                  Expanded(
                                    child: Text(
                                      '${AppStringsAr.statementMediatorPrefix}${msg.mediatorName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: scheme.onTertiaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  if (msg.feeAmountMinorUnits != null &&
                                      msg.feeAmountMinorUnits! > 0) ...[
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color: scheme.tertiary
                                          .withValues(alpha: 0.3),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: SpacingTokens.xs),
                                    ),
                                    Text(
                                      AppStringsAr.statementFeePrefix,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: scheme.tertiary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    QaydMoneyDisplay(
                                      money: Money.fromMinorUnits(
                                          msg.feeAmountMinorUnits!, currency),
                                      size: QaydMoneyDisplaySize.small,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        // ──── Footer: date + running balance ────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.md,
                            vertical: SpacingTokens.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: custom.surfaceElevated.withValues(
                              alpha: 0.5,
                            ),
                            border: Border(
                              top: BorderSide(
                                color: custom.subtleBorder.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Date
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 10,
                                    ),
                              ),
                              const Spacer(),
                              // Running balance
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 11,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${AppStringsAr.statementRunningBalance}: ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                    ),
                              ),
                              _BalanceAmountText(
                                minorUnits: msg.runningBalanceMinorUnits,
                                currencySymbol: msg.currencySymbol,
                                currencyDigits: msg.currencyDigits,
                                fontSize: 10,
                              ),
                            ],
                          ),
                        ),

                        // ──── Action buttons ────
                        _actionArea(context),
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

  bool get _isDraft => msg.voucherStateCode == VoucherState.draft.name;
  bool get _isRejected =>
      msg.signatureStatusCode == AgreementStatus.rejected.name;

  Widget _actionArea(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;

    // Only the Receiver (Counterparty) can Accept or Reject a pending voucher
    final showAcceptReject = !msg.isCreator && _isDraft && !_isRejected;

    // The Creator can withdraw their voucher as long as it is still a draft
    // (meaning the counterparty hasn't accepted it yet)
    final showWithdraw = msg.isCreator && _isDraft;

    // The Creator can only run the Corrective Resubmission flow (Resubmit)
    // if the counterparty explicitly rejected it
    final showResubmit = msg.isCreator && _isDraft && _isRejected;

    if (isUnified) return const SizedBox.shrink();
    if (!showAcceptReject && !showWithdraw && !showResubmit) {
      return const SizedBox.shrink();
    }

    final statusColor = _statusColor(context);

    if (showAcceptReject) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.04),
          border: Border(
            top: BorderSide(color: statusColor.withValues(alpha: 0.15)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    mutating ? null : () async => onAccept(msg.voucherId),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(AppStringsAr.statementChatAccept),
                style: FilledButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  ),
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    mutating ? null : () async => onReject(msg.voucherId),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(AppStringsAr.statementChatReject),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.errorDeep,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.sm,
                  ),
                  side: BorderSide(
                    color: ColorTokens.errorDeep.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: custom.draftState.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: custom.draftState.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          if (showResubmit)
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    mutating ? null : () async => onResubmit(msg.voucherId),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(AppStringsAr.statementChatResubmit),
                style: OutlinedButton.styleFrom(
                  foregroundColor: custom.confirmedState,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.sm,
                  ),
                  side: BorderSide(
                    color: custom.confirmedState.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  ),
                ),
              ),
            ),
          if (showResubmit && showWithdraw)
            const SizedBox(width: SpacingTokens.sm),
          if (showWithdraw)
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    mutating ? null : () async => onWithdraw(msg.voucherId),
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: Text(AppStringsAr.statementChatWithdraw),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.errorDeep,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.sm,
                  ),
                  side: BorderSide(
                    color: ColorTokens.errorDeep.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Shared Balance Amount Text ───────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _BalanceAmountText extends StatelessWidget {
  const _BalanceAmountText({
    required this.minorUnits,
    required this.currencySymbol,
    required this.currencyDigits,
    this.large = false,
    this.fontSize,
  });

  final int minorUnits;
  final String currencySymbol;
  final int currencyDigits;
  final bool large;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final isPositive = minorUnits > 0;
    final isNegative = minorUnits < 0;
    final color = isPositive
        ? custom.credit
        : isNegative
            ? ColorTokens.errorDeep
            : custom.confirmedState;

    num divisor = 1;
    for (var i = 0; i < currencyDigits; i++) {
      divisor *= 10;
    }
    final abs = minorUnits.abs();
    final major = abs / divisor;
    final formatted = major.toStringAsFixed(currencyDigits);

    final effectiveFontSize = fontSize ?? (large ? 18.0 : 13.0);
    final text = '$formatted $currencySymbol';

    return Text.rich(
      buildNumericalScaledSpan(
        text,
        TextStyle(
          color: color,
          fontWeight: large ? FontWeight.w800 : FontWeight.w600,
          fontSize: effectiveFontSize,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onChanged});

  final StatementChatViewMode mode;
  final ValueChanged<StatementChatViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.xs,
      ),
      child: SegmentedButton<StatementChatViewMode>(
        segments: [
          ButtonSegment<StatementChatViewMode>(
            value: StatementChatViewMode.myAccounts,
            label: Text(
              AppStringsAr.statementViewModeMy,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.account_circle_outlined, size: 18),
          ),
          ButtonSegment<StatementChatViewMode>(
            value: StatementChatViewMode.otherPartyAccounts,
            label: Text(
              AppStringsAr.statementViewModeOther,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.people_alt_outlined, size: 18),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: WidgetStateProperty.all(
            BorderSide(color: scheme.outline.withOpacity(0.2)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer.withOpacity(0.4);
            }
            return null;
          }),
        ),
      ),
    );
  }
}
