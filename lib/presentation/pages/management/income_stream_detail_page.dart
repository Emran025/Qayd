import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/account_statement_chat_message_dto.dart';
import 'package:qayd/domain/value_objects/income_source_type.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_cubit.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_state.dart';
import 'package:qayd/presentation/pages/management/widgets/ledger_filter_sheet.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/account_statement_pdf_export.dart';
import 'package:qayd/presentation/utils/statement_chat_export.dart';
import 'package:qayd/presentation/utils/account_archive_helper.dart';
import 'package:qayd/presentation/pages/accounts/widgets/account_default_cost_centers_section.dart';
import 'package:qayd/di/injection_container.dart';

enum _IncomeMenuAction { exportPdf, exportExcel, archive }

/// A professional, dashboard-like page dedicated to visualizing
/// specific management entities (Assets, Expenses, Professions) with ledger format.
class IncomeStreamDetailPage extends StatelessWidget {
  const IncomeStreamDetailPage({super.key, required this.summary});

  final AccountSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountDetailCubit>(
          create: (_) => AccountDetailCubit(
            InjectionContainer.getAccountDetailsUseCase,
          )..load(summary.id),
        ),
        BlocProvider<StatementChatCubit>(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            getCostCenterDetails:
                InjectionContainer.getCostCenterDetailsUseCase,
            counterpartyAccountId: summary.id,
          )..load(),
        ),
      ],
      child: _IncomeStreamDetailBody(summary: summary),
    );
  }
}

class _IncomeStreamDetailBody extends StatelessWidget {
  const _IncomeStreamDetailBody({required this.summary});

  final AccountSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metadata = summary.metadata ?? {};

    // Determine the exact type to style appropriately
    final typeKey = metadata['income_source_type'] as String?;
    final sourceType = IncomeSourceType.fromKey(typeKey);
    final isExpense = summary.standardClassificationKind == 'personalExpenses';

    Color primaryColor = scheme.primary;
    IconData headerIcon = Icons.account_balance_wallet_outlined;
    String typeLabel = AppStrings.incomeStreamTracker;

    if (isExpense) {
      primaryColor = ColorTokens.warningAmber;
      headerIcon = Icons.receipt_long_rounded;
      typeLabel = AppStrings.incomeStreamExpense;
    } else if (sourceType == IncomeSourceType.investmentAsset) {
      primaryColor = ColorTokens.emerald400;
      headerIcon = Icons.trending_up_rounded;
      typeLabel = AppStrings.incomeStreamAsset;
    } else if (sourceType == IncomeSourceType.possession) {
      primaryColor = Colors.blueAccent;
      headerIcon = Icons.inventory_2_outlined;
      typeLabel = AppStrings.incomeStreamPossession;
    } else if (sourceType == IncomeSourceType.profession) {
      primaryColor = ColorTokens.debitBlue;
      headerIcon = Icons.work_outline_rounded;
      typeLabel = AppStrings.incomeStreamProfession;
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: QaydAppBar(
        title: summary.name,
        actions: [
          PopupMenuButton<_IncomeMenuAction>(
            icon: Icon(Icons.more_vert_rounded),
            onSelected: (action) async {
              final chatState = context.read<StatementChatCubit>().state;
              switch (action) {
                case _IncomeMenuAction.exportPdf:
                  if (chatState is StatementChatReady) {
                    shareStatementChatAsPdf(
                      context,
                      accountId: summary.id,
                      accountName: summary.name,
                      filter: chatState.filter,
                      messages: chatState.messages,
                      broughtForwardByCurrency:
                          chatState.broughtForwardByCurrency,
                      finalBalanceByCurrency: chatState.finalBalanceByCurrency,
                    );
                  } else {
                    shareAccountStatementAsPdf(context, accountId: summary.id);
                  }
                  break;
                case _IncomeMenuAction.exportExcel:
                  if (chatState is StatementChatReady) {
                    shareStatementChatAsExcel(
                      context,
                      accountId: summary.id,
                      accountName: summary.name,
                      filter: chatState.filter,
                      messages: chatState.messages,
                      broughtForwardByCurrency:
                          chatState.broughtForwardByCurrency,
                      currencyDigits: chatState.currencyDigits,
                    );
                  }
                  break;
                case _IncomeMenuAction.archive:
                  confirmAndArchiveAccount(context, summary.id);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: _IncomeMenuAction.exportPdf,
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined,
                        color: Colors.red, size: 20),
                    SizedBox(width: SpacingTokens.sm),
                    Text(AppStrings.exportPdfStatement),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _IncomeMenuAction.exportExcel,
                child: Row(
                  children: [
                    Icon(Icons.table_view_rounded,
                        color: Colors.green, size: 20),
                    SizedBox(width: SpacingTokens.sm),
                    Text(AppStrings.exportExcelStatement),
                  ],
                ),
              ),
              // const PopupMenuDivider(),
              PopupMenuItem(
                value: _IncomeMenuAction.archive,
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined,
                        size: 20, color: ColorTokens.errorSoft),
                    SizedBox(width: SpacingTokens.sm),
                    Text(AppStrings.archiveAccountAction,
                        style: TextStyle(color: ColorTokens.errorSoft)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<StatementChatCubit, StatementChatState>(
        builder: (context, chatState) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AccountDetailCubit>().load(summary.id);
              await context.read<StatementChatCubit>().load();
            },
            child: CustomScrollView(
              slivers: [
                // Dashboard Header
                SliverToBoxAdapter(
                  child: _buildHeader(
                      context, primaryColor, headerIcon, typeLabel, scheme),
                ),

                // Metadata Ribbon
                if (metadata.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMetadataRibbon(context, metadata, scheme),
                  ),

                // Default Cost Centers Section
                SliverToBoxAdapter(
                  child: BlocBuilder<AccountDetailCubit, AccountDetailState>(
                    builder: (context, detailState) {
                      if (detailState is AccountDetailReady) {
                        return Padding(
                          padding: const EdgeInsets.only(top: SpacingTokens.lg),
                          child: AccountDefaultCostCentersSection(
                            data: detailState.data,
                          ),
                        );
                      }
                      return SizedBox();
                    },
                  ),
                ),

                // Smart Chart section
                if (chatState is StatementChatReady &&
                    chatState.messages.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSmartChart(
                        context, chatState, primaryColor, isExpense),
                  ),

                // Filters & Tools Row
                if (chatState is StatementChatReady)
                  SliverToBoxAdapter(
                    child: _buildFiltersRow(context, chatState),
                  ),

                // Ledger List
                if (chatState is StatementChatLoading ||
                    chatState is StatementChatInitial)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (chatState is StatementChatReady)
                  if (chatState.messages.isEmpty)
                    SliverFillRemaining(
                      child:
                          Center(child: Text(AppStrings.incomeStreamNoData)),
                    )
                  else
                    _buildLedgerList(context, chatState, primaryColor)
                else if (chatState is StatementChatFailure)
                  SliverFillRemaining(
                    child:
                        Center(child: Text(AppStrings.incomeStreamLoadError)),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: SpacingTokens.xxl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor,
      IconData headerIcon, String typeLabel, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primaryColor.withValues(alpha: 0.15),
            scheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: primaryColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(headerIcon, color: primaryColor, size: 28),
          ),
          SizedBox(width: SpacingTokens.lg),
          // Balance and Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(RadiusTokens.xs),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: SpacingTokens.sm),
                BlocBuilder<AccountDetailCubit, AccountDetailState>(
                  builder: (context, state) {
                    if (state is AccountDetailReady) {
                      int minor = 0;
                      String cur =
                          summary.metadata?['currency_code'] as String? ?? '';
                      if (state.data.balancesMinorUnits.isNotEmpty) {
                        cur = state.data.balancesMinorUnits.keys.first;
                        minor = state.data.balancesMinorUnits[cur]!;
                      }
                      final val = minor / 100.0;
                      return QaydText(
                        '${val.toStringAsFixed(2)} $cur',
                        slot: QaydTextStyleSlot.headlineMedium,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRibbon(
      BuildContext context, Map<String, dynamic> metadata, ColorScheme scheme) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
        children: [
          if (metadata['purchase_price'] != null)
            _MetaRibbonItem(
              icon: Icons.monetization_on_outlined,
              label:
                  '${AppStrings.incomeStreamPurchasePrice}${metadata['purchase_price']} ${metadata['purchase_currency'] ?? ''}',
            ),
          if (metadata['profession_name'] != null)
            _MetaRibbonItem(
                icon: Icons.badge_outlined, label: metadata['profession_name']),
          if (metadata['hourly_rate'] != null)
            _MetaRibbonItem(
                icon: Icons.timer_outlined,
                label:
                    '${metadata['hourly_rate']} ${AppStrings.incomeStreamPerHour}'),
          if (metadata['purchase_date'] != null)
            _MetaRibbonItem(
              icon: Icons.calendar_today_rounded,
              label:
                  '${AppStrings.incomeStreamDatePrefix}${(metadata['purchase_date'] as String).split('T').first}',
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context, StatementChatReady state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          QaydText(AppStrings.ledgerMovement,
              slot: QaydTextStyleSlot.labelMedium),
          FilledButton.tonalIcon(
            onPressed: () async {
              final cubit = context.read<StatementChatCubit>();
              final result =
                  await showLedgerFilterSheet(context, initial: state.filter);
              if (result != null) cubit.setFilter(result);
            },
            icon: Icon(Icons.filter_list_rounded, size: 18),
            label: Text(state.hasActiveFilters
                ? AppStrings.filterApplied
                : AppStrings.filterLedger),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: state.hasActiveFilters
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartChart(BuildContext context, StatementChatReady state,
      Color primaryColor, bool isExpense) {
    final scheme = Theme.of(context).colorScheme;

    // Sort chronological: oldest to newest for the chart
    final chronologicalMsgs =
        List<AccountStatementChatMessageDto>.from(state.messages)
          ..sort((a, b) => a.dateIso.compareTo(b.dateIso));

    List<FlSpot> spots = [];
    final firstMsg = chronologicalMsgs.first;
    double runningBalance =
        (state.broughtForwardByCurrency[firstMsg.currencyCode] ?? 0) / 100.0;

    // If it's an expense, we show pure cumulative spending
    // If an asset, we track running balance
    int index = 0;

    // For x-axis labels
    final Map<int, String> xLabels = {};

    for (final m in chronologicalMsgs) {
      if (m.signatureStatusCode == AgreementStatus.rejected.name) continue;

      double impact = m.amountMinorUnits / 100.0;
      if (m.direction == 'outgoing') impact = -impact;

      if (isExpense) {
        // Expenses grow positively in our perspective (spending accumulating)
        runningBalance += (m.direction == 'incoming' ? impact : -impact).abs();
      } else {
        runningBalance += impact;
      }

      spots.add(FlSpot(index.toDouble(), runningBalance));

      final dt = DateTime.parse(m.dateIso);
      xLabels[index] = '${dt.day}/${dt.month}';
      index++;
    }

    if (spots.isEmpty) return SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(
          SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, 0),
      padding: const EdgeInsets.all(SpacingTokens.lg),
      height: 250,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: primaryColor),
              SizedBox(width: SpacingTokens.sm),
              QaydText(AppStrings.financialBalancePerformance,
                  slot: QaydTextStyleSlot.titleSmall, color: scheme.onSurface),
            ],
          ),
          SizedBox(height: SpacingTokens.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.onSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        return LineTooltipItem(
                          '${touchedSpot.y.toStringAsFixed(2)}\n',
                          TextStyle(
                              color: scheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          children: [
                            TextSpan(
                              text: xLabels[touchedSpot.x.toInt()] ?? '',
                              style: TextStyle(
                                  color: scheme.surface.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: TextStyle(
                                fontSize: 10, color: scheme.onSurfaceVariant),
                            overflow: TextOverflow.visible,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (spots.length > 7)
                          ? (spots.length / 5).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final lbl = xLabels[value.toInt()];
                        if (lbl == null) return SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(lbl,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5)),
                    dotData: FlDotData(
                      show: spots.length < 15,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: scheme.surface,
                        strokeWidth: 2,
                        strokeColor: primaryColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.25),
                          primaryColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerList(
      BuildContext context, StatementChatReady state, Color primaryColor) {
    // Reverse chronologically for the list so newest is top
    final messages = List<AccountStatementChatMessageDto>.from(state.messages);

    // Pick currency from newest message if available
    final newestMsg = messages.isNotEmpty ? messages.first : null;
    final balanceCurrency = newestMsg?.currencyCode ?? '';

    double currentBalanceMinor =
        (state.finalBalanceByCurrency[balanceCurrency] ?? 0).toDouble();
    final List<Map<String, dynamic>> ledgerRows = [];

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final isRejected =
          msg.signatureStatusCode == AgreementStatus.rejected.name;
      final valMinor = isRejected ? 0.0 : msg.amountMinorUnits.toDouble();
      final isOutwards = msg.direction == 'outgoing';

      final debitValue = isOutwards ? 0.0 : valMinor;
      final creditValue = isOutwards ? valMinor : 0.0;

      ledgerRows.add({
        'msg': msg,
        'balanceMinor': currentBalanceMinor,
        'debit': debitValue,
        'credit': creditValue,
        'isRejected': isRejected,
      });

      // Retract balance backwards
      if (!isRejected) {
        if (isOutwards) {
          currentBalanceMinor += valMinor;
        } else {
          currentBalanceMinor -= valMinor;
        }
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final row = ledgerRows[index];
            final AccountStatementChatMessageDto msg = row['msg'];
            final custom = Theme.of(context).extension<QaydCustomColors>()!;

            final dt = DateTime.parse(msg.dateIso);
            final day = DateFormat.d('ar').format(dt);
            final month = DateFormat.MMM('ar').format(dt);

            final df = NumberFormat.currency(
                symbol: msg.currencySymbol, decimalDigits: msg.currencyDigits);

            // Standard Accounting Ledger colors
            final debitColor = custom.debit;
            final creditColor = custom.credit;

            return InkWell(
              onTap: () => VoucherDetailPage.show(context, msg.voucherId),
              child: Container(
                margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.5)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Date Badge
                      Container(
                        width: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(RadiusTokens.md)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(day,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(month,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),

                      // Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.description.isNotEmpty
                                    ? msg.description
                                    : msg.otherPartyName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: row['isRejected']
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                      msg.direction == 'incoming'
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      size: 12,
                                      color: msg.direction == 'incoming'
                                          ? debitColor
                                          : creditColor),
                                  SizedBox(width: 4),
                                  Text(
                                    msg.otherPartyName,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                  if (row['isRejected']) ...[
                                    SizedBox(width: SpacingTokens.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: ColorTokens.errorSoft
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                      child: Text(AppStrings.statusRejected,
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: ColorTokens.errorSoft)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Financial Amounts
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (row['debit'] > 0)
                              Text(
                                '+ ${df.format(row['debit'] / 100.0)}',
                                style: TextStyle(
                                    color: debitColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            if (row['credit'] > 0)
                              Text(
                                '- ${df.format(row['credit'] / 100.0)}',
                                style: TextStyle(
                                    color: creditColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            SizedBox(height: 2),
                            Text(
                              df.format(row['balanceMinor'] / 100.0),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: messages.length,
        ),
      ),
    );
  }
}

class _MetaRibbonItem extends StatelessWidget {
  const _MetaRibbonItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: SpacingTokens.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
