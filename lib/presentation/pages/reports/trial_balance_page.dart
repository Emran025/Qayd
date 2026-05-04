import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';
import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/atomic/qayd_empty_state.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_cubit.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_state.dart';
import 'package:qayd/presentation/pages/reports/balance_sheet_page.dart';
import 'package:qayd/presentation/pages/reports/balance_sheet_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class TrialBalancePage extends StatefulWidget {
  const TrialBalancePage({super.key});

  @override
  State<TrialBalancePage> createState() => _TrialBalancePageState();
}

class _TrialBalancePageState extends State<TrialBalancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              TrialBalanceCubit(InjectionContainer.generateTrialBalanceUseCase)
                ..load(),
        ),
        BlocProvider(
          create: (_) =>
              BalanceSheetCubit(InjectionContainer.generateBalanceSheetUseCase)
                ..load(),
        ),
      ],
      child: QaydScaffold(
        appBar: QaydAppBar(
          showNotifications: true,
          title: AppStrings.financialReports,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: gold,
            tabs: [
              Tab(text: AppStrings.trialBalance),
              Tab(text: AppStrings.balanceSheet),
            ],
          ),
          actions: [
            Builder(builder: (context) {
              return PopupMenuButton<String>(
                icon: Icon(Icons.file_download_outlined),
                tooltip: AppStrings.exportTheReport,
                onSelected: (val) {
                  if (_tabController.index == 0) {
                    if (val == 'pdf') {
                      context.read<TrialBalanceCubit>().exportPdf();
                    }
                    if (val == 'excel') {
                      context.read<TrialBalanceCubit>().exportExcel();
                    }
                  } else {
                    if (val == 'pdf') {
                      context.read<BalanceSheetCubit>().exportPdf();
                    }
                    if (val == 'excel') {
                      context.read<BalanceSheetCubit>().exportExcel();
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                        SizedBox(width: 8),
                        Text(AppStrings.exportPdf),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_view_outlined, color: Colors.green),
                        SizedBox(width: 8),
                        Text(AppStrings.excelExport),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _TrialBalanceTab(),
            BalanceSheetView(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── TRIAL BALANCE TAB ────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _TrialBalanceTab extends StatelessWidget {
  const _TrialBalanceTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
      builder: (context, state) {
        return switch (state) {
          TrialBalanceInitial() => const SizedBox.shrink(),
          TrialBalanceLoading() => Center(child: CircularProgressIndicator()),
          TrialBalanceFailure(:final failure) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QaydText(failure.messageAr,
                      slot: QaydTextStyleSlot.bodyLarge),
                  SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.read<TrialBalanceCubit>().load(),
                    child: Text(AppStrings.retryAction),
                  ),
                ],
              ),
            ),
          TrialBalanceReady(:final output, :final isExporting) => Stack(
              children: [
                _TrialBalanceBody(output: output),
                if (isExporting)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
        };
      },
    );
  }
}

class _TrialBalanceBody extends StatelessWidget {
  const _TrialBalanceBody({required this.output});
  final TrialBalanceOutput output;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TrialBalanceCubit>().load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          child: Column(
            children: [
              _TrialBalanceLedger(output: output),
              SizedBox(height: SpacingTokens.xl),
              _MultiCurrencyFooter(output: output),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── LEDGER TABLE ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _TrialBalanceLedger extends StatefulWidget {
  const _TrialBalanceLedger({required this.output});
  final TrialBalanceOutput output;

  @override
  State<_TrialBalanceLedger> createState() => _TrialBalanceLedgerState();
}

class _TrialBalanceLedgerState extends State<_TrialBalanceLedger> {
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  /// Groups consecutive lines by accountId, preserving order.
  List<_AccountGroup> _groupLines(List<TrialBalanceLineDto> lines) {
    final groups = <_AccountGroup>[];
    _AccountGroup? current;
    for (final line in lines) {
      if (current != null && current.accountId == line.accountId) {
        current.currencyLines.add(line);
      } else {
        current = _AccountGroup(
          accountId: line.accountId,
          accountCode: line.accountCode,
          accountName: line.accountName,
          accountLevel: line.accountLevel,
          isParent: line.isParent,
          currencyLines: [line],
        );
        groups.add(current);
      }
    }
    return groups;
  }

  double _calculateBalanceColumnWidth(List<TrialBalanceLineDto> lines) {
    int maxFormattedLen = 0;
    for (final line in lines) {
      final amounts = [
        line.openingDebitMinorUnits,
        line.openingCreditMinorUnits,
        line.periodDebitMinorUnits,
        line.periodCreditMinorUnits,
        line.closingDebitMinorUnits,
        line.closingCreditMinorUnits,
      ];
      for (final a in amounts) {
        if (a == 0) continue;
        final sMajor = (a.abs() ~/ 100).toString();
        final commas = sMajor.length > 3 ? (sMajor.length - 1) ~/ 3 : 0;
        final len = sMajor.length + commas + 3; // +1 for dot + 2 for decimals
        if (len > maxFormattedLen) maxFormattedLen = len;
      }
    }
    // Estimate width: 8.5px per character + padding.
    final double neededForMoney = (maxFormattedLen * 8.5) + 16.0;
    // Header labels like AppStrings.openingBalances need around 180px minimum.
    return max(180.0, neededForMoney * 2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qayd = Theme.of(context).extension<QaydCustomColors>()!;

    if (widget.output.lines.isEmpty) {
      return QaydEmptyState(
        icon: Icons.analytics_outlined,
        title: AppStrings.trialBalanceEmpty,
        description: AppStrings.noAccountBalancesWere,
      );
    }

    final groups = _groupLines(widget.output.lines);
    final balanceWidth = _calculateBalanceColumnWidth(widget.output.lines);

    return Scrollbar(
      controller: _hScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _hScroll,
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 32,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: qayd.subtleBorder, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Branded header band ─────────────────────────────────
                _TableHeader(
                  qayd: qayd,
                  scheme: scheme,
                  balanceColumnWidth: balanceWidth,
                ),

                // ── Data rows ───────────────────────────────────────────
                ...List.generate(groups.length, (i) {
                  final group = groups[i];
                  return _AccountGroupWidget(
                    group: group,
                    isEvenGroup: i.isEven,
                    balanceColumnWidth: balanceWidth,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── TABLE HEADER (World-class branded) ───────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.qayd,
    required this.scheme,
    required this.balanceColumnWidth,
  });
  final QaydCustomColors qayd;
  final ColorScheme scheme;
  final double balanceColumnWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Primary Navy header band ────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorTokens.navy950, ColorTokens.navy800],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الحساب (merged name+code column)
                SizedBox(
                  width: 240,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.account_tree_outlined,
                            size: 15, color: qayd.goldAccent),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.theAccount,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _VerticalDivider(color: ColorTokens.navy700),

                // Currency column header area
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text(
                      AppStrings.currency,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                _VerticalDivider(color: ColorTokens.navy700),

                _BalanceColumnHeader(
                  label: AppStrings.openingBalances,
                  icon: Icons.lock_clock_outlined,
                  gold: qayd.goldAccent,
                  width: balanceColumnWidth,
                ),
                _VerticalDivider(color: ColorTokens.navy700),
                _BalanceColumnHeader(
                  label: AppStrings.periodMovement,
                  icon: Icons.swap_horiz_rounded,
                  gold: qayd.goldAccent,
                  width: balanceColumnWidth,
                ),
                _VerticalDivider(color: ColorTokens.navy700),
                _BalanceColumnHeader(
                  label: AppStrings.closingBalances,
                  icon: Icons.flag_rounded,
                  gold: qayd.goldAccent,
                  width: balanceColumnWidth,
                ),
              ],
            ),
          ),
        ),

        // ── Sub-header: Debit / Credit labels ───────────────────────────
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: qayd.subtleBorder, width: 0.8),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Empty space under AppStrings.theAccount and Currency
                SizedBox(width: 240),
                _VerticalDivider(color: scheme.outlineVariant),
                SizedBox(width: 48),
                _VerticalDivider(color: scheme.outlineVariant),

                _dualSubHeader(qayd, balanceColumnWidth),
                _VerticalDivider(color: scheme.outlineVariant),
                _dualSubHeader(qayd, balanceColumnWidth),
                _VerticalDivider(color: scheme.outlineVariant),
                _dualSubHeader(qayd, balanceColumnWidth),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dualSubHeader(QaydCustomColors qayd, double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                AppStrings.debtor,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: qayd.credit,
                ),
              ),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 0.5,
            color: Colors.grey.withAlpha(60),
          ),
          Expanded(
            child: Center(
              child: Text(
                AppStrings.creditor,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: qayd.debit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceColumnHeader extends StatelessWidget {
  const _BalanceColumnHeader({
    required this.label,
    required this.icon,
    required this.gold,
    required this.width,
  });
  final String label;
  final IconData icon;
  final Color gold;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: gold),
              SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 0.8,
      thickness: 0.8,
      color: color,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── ACCOUNT GROUP (merged code + name vertically) ──────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _AccountGroupWidget extends StatelessWidget {
  const _AccountGroupWidget({
    required this.group,
    required this.isEvenGroup,
    required this.balanceColumnWidth,
  });
  final _AccountGroup group;
  final bool isEvenGroup;
  final double balanceColumnWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qayd = Theme.of(context).extension<QaydCustomColors>()!;
    final isParent = group.isParent;
    final isRoot = group.accountLevel == 0;
    final isBold = isRoot || isParent;

    // Visual hierarchy: parents get elevated surface, alternating rows for data
    final bgColor = isParent
        ? scheme.surfaceContainer
        : isEvenGroup
            ? scheme.surface
            : scheme.surfaceContainerLow;

    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(
              color: isParent
                  ? qayd.subtleBorder
                  : scheme.outlineVariant.withAlpha(60),
              width: isParent ? 0.8 : 0.4,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── الحساب (code + name merged cell vertically) ────────────
            SizedBox(
              width: 240,
              child: Padding(
                padding: EdgeInsets.only(
                  right: 12 + (group.accountLevel * 14).toDouble(),
                  left: 8,
                  top: 8,
                  bottom: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccountCell(
                      code: group.accountCode,
                      name: group.accountName,
                      currencyCode:
                          null, // Always null to show in its own column
                      isBold: isBold,
                      isParent: group.isParent,
                      scheme: scheme,
                      qayd: qayd,
                    ),
                  ],
                ),
              ),
            ),

            _VerticalDivider(color: scheme.outlineVariant.withAlpha(50)),

            // ── المبالغ المتعددة والعملات ─────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: group.currencyLines.asMap().entries.map((entry) {
                final idx = entry.key;
                final line = entry.value;
                final isLast = idx == group.currencyLines.length - 1;

                return _CurrencyValuesRow(
                  line: line,
                  isLast: isLast,
                  isBold: isBold,
                  qayd: qayd,
                  scheme: scheme,
                  hasMultipleCurrencies: group.currencyLines.length > 1,
                  balanceColumnWidth: balanceColumnWidth,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyValuesRow extends StatelessWidget {
  const _CurrencyValuesRow({
    required this.line,
    required this.isLast,
    required this.isBold,
    required this.qayd,
    required this.scheme,
    required this.hasMultipleCurrencies,
    required this.balanceColumnWidth,
  });

  final TrialBalanceLineDto line;
  final bool isLast;
  final bool isBold;
  final QaydCustomColors qayd;
  final ColorScheme scheme;
  final bool hasMultipleCurrencies;
  final double balanceColumnWidth;

  @override
  Widget build(BuildContext context) {
    final cur = CurrencyCode(
      code: line.currencyCode,
      nameAr: '',
      symbol: line.currencySymbol,
      fractionalDigits: line.currencyDigits,
    );

    final weight = isBold ? FontWeight.w700 : FontWeight.w400;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant.withAlpha(40)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ensure width is ALWAYS 48 to align with the new Header column.
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: _CurrencyBadge(
                  code: line.currencyCode,
                  scheme: scheme,
                ),
              ),
            ),

            _VerticalDivider(color: scheme.outlineVariant.withAlpha(50)),

            // ── افتتاحي ─────────────────────────────────────────────────
            _DualMoneyCell(
              debit: line.openingDebitMinorUnits,
              credit: line.openingCreditMinorUnits,
              cur: cur,
              weight: weight,
              qayd: qayd,
              width: balanceColumnWidth,
            ),

            _VerticalDivider(color: scheme.outlineVariant.withAlpha(50)),

            // ── الحركة ──────────────────────────────────────────────────
            _DualMoneyCell(
              debit: line.periodDebitMinorUnits,
              credit: line.periodCreditMinorUnits,
              cur: cur,
              weight: weight,
              qayd: qayd,
              width: balanceColumnWidth,
            ),

            _VerticalDivider(color: scheme.outlineVariant.withAlpha(50)),

            // ── الختامي ─────────────────────────────────────────────────
            _DualMoneyCell(
              debit: line.closingDebitMinorUnits,
              credit: line.closingCreditMinorUnits,
              cur: cur,
              weight: weight,
              qayd: qayd,
              width: balanceColumnWidth,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── ACCOUNT CELL (code + name + optional currency inline) ────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _AccountCell extends StatelessWidget {
  const _AccountCell({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.isBold,
    required this.isParent,
    required this.scheme,
    required this.qayd,
  });

  final String code;
  final String name;
  final String? currencyCode;
  final bool isBold;
  final bool isParent;
  final ColorScheme scheme;
  final QaydCustomColors qayd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Account code chip
        if (code.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: isParent
                  ? ColorTokens.navy900.withAlpha(20)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: scheme.outlineVariant.withAlpha(80),
                width: 0.5,
              ),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),

        SizedBox(width: 4),

        // Account name
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: isBold ? 12 : 11.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: scheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Inline currency badge (only for single-currency accounts)
        if (currencyCode != null) ...[
          SizedBox(width: 4),
          _CurrencyBadge(code: currencyCode!, scheme: scheme),
        ],
      ],
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  const _CurrencyBadge({required this.code, required this.scheme});
  final String code;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: ColorTokens.navy900.withAlpha(15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: ColorTokens.goldAccent.withAlpha(50),
          width: 0.5,
        ),
      ),
      child: Text(
        CurrencyUtil.getLocalizedName(code).replaceAll('﷼', AppStrings.sar),
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: ColorTokens.navy700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── DUAL MONEY CELL (debit | credit) ─────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _DualMoneyCell extends StatelessWidget {
  const _DualMoneyCell({
    required this.debit,
    required this.credit,
    required this.cur,
    required this.weight,
    required this.qayd,
    required this.width,
  });

  final int debit;
  final int credit;
  final CurrencyCode cur;
  final FontWeight weight;
  final QaydCustomColors qayd;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(child: _moneyText(debit, cur, weight)),
          VerticalDivider(
            width: 1,
            thickness: 0.4,
            color: Colors.grey.withAlpha(40),
          ),
          Expanded(child: _moneyText(credit, cur, weight)),
        ],
      ),
    );
  }

  Widget _moneyText(int amount, CurrencyCode cur, FontWeight weight) {
    if (amount == 0) {
      return Center(
        child: Text('—',
            style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(100))),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: QaydMoneyDisplay(
          money: Money.fromMinorUnits(amount, cur),
          size: QaydMoneyDisplaySize.small,
          fontWeight: weight,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── HELPER DATA ──────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _AccountGroup {
  _AccountGroup({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountLevel,
    required this.isParent,
    required this.currencyLines,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final int accountLevel;
  final bool isParent;
  final List<TrialBalanceLineDto> currencyLines;
}

// ═══════════════════════════════════════════════════════════════════════════
// ── FOOTER (per-currency totals) ─────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _MultiCurrencyFooter extends StatelessWidget {
  const _MultiCurrencyFooter({required this.output});
  final TrialBalanceOutput output;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: output.currencySections.values
          .map((s) => _CurrencySectionFooter(section: s))
          .toList(),
    );
  }
}

class _CurrencySectionFooter extends StatelessWidget {
  const _CurrencySectionFooter({required this.section});
  final TrialBalanceCurrencySectionDto section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qayd = Theme.of(context).extension<QaydCustomColors>()!;
    final currency = CurrencyCode(
      code: section.currencyCode,
      nameAr: '',
      symbol: section.currencySymbol,
      fractionalDigits: section.currencyDigits,
    );

    final balanced = section.isBalanced;
    final statusColor = balanced ? ColorTokens.emerald600 : scheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Title row ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  balanced ? Icons.verified_rounded : Icons.warning_rounded,
                  color: statusColor,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  '${AppStrings.trialBalanceGrandTotal} — ${CurrencyUtil.getLocalizedName(section.currencyCode).replaceAll('﷼', AppStrings.sar)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ColorTokens.navy900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(50)),
                  ),
                  child: Text(
                    balanced ? AppStrings.balanced1 : AppStrings.unbalanced,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Summary rows ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow(
                  label: AppStrings.editorial,
                  debit: section.openingDebitMinorUnits,
                  credit: section.openingCreditMinorUnits,
                  cur: currency,
                  qayd: qayd,
                ),
                SizedBox(height: 8),
                _SummaryRow(
                  label: AppStrings.movement,
                  debit: section.periodDebitMinorUnits,
                  credit: section.periodCreditMinorUnits,
                  cur: currency,
                  qayd: qayd,
                ),
                SizedBox(height: 12),
                Divider(height: 1, color: scheme.outlineVariant),
                SizedBox(height: 12),
                _SummaryRow(
                  label: AppStrings.closing,
                  debit: section.closingDebitMinorUnits,
                  credit: section.closingCreditMinorUnits,
                  cur: currency,
                  qayd: qayd,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.debit,
    required this.credit,
    required this.cur,
    required this.qayd,
    this.isBold = false,
  });

  final String label;
  final int debit;
  final int credit;
  final CurrencyCode cur;
  final QaydCustomColors qayd;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final weight = isBold ? FontWeight.w700 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.creditor,
                  style:
                      TextStyle(fontSize: 9, color: qayd.debit.withAlpha(150))),
              QaydMoneyDisplay(
                money: Money.fromMinorUnits(debit, cur),
                size: QaydMoneyDisplaySize.small,
                fontWeight: weight,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 1,
              height: 14,
              color: Colors.grey.withAlpha(60),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.debtor,
                  style: TextStyle(
                      fontSize: 9, color: qayd.credit.withAlpha(150))),
              QaydMoneyDisplay(
                money: Money.fromMinorUnits(credit, cur),
                size: QaydMoneyDisplaySize.small,
                fontWeight: weight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
