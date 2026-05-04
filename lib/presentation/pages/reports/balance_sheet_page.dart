import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/balance_sheet_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/presentation/pages/reports/balance_sheet_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class BalanceSheetView extends StatelessWidget {
  const BalanceSheetView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BalanceSheetCubit(InjectionContainer.generateBalanceSheetUseCase)
            ..load(),
      child: const _BalanceSheetBody(),
    );
  }
}

class _BalanceSheetBody extends StatelessWidget {
  const _BalanceSheetBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceSheetCubit, BalanceSheetState>(
      builder: (context, state) {
        if (state is BalanceSheetLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is BalanceSheetFailure) {
          return Center(
            child:
                Text(state.message, style: const TextStyle(color: Colors.red)),
          );
        }
        if (state is BalanceSheetReady) {
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => context.read<BalanceSheetCubit>().load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  child: Column(
                    children: [
                      // 1. Graphical Insights (Charts)
                      if (state.output.currencySections.isNotEmpty)
                        _BalanceSheetChartsCarousel(
                          output: state.output,
                        ),
                      SizedBox(height: SpacingTokens.xl),

                      // 2. Data Table with merged account name fields
                      _BalanceSheetLedger(output: state.output),
                      SizedBox(height: SpacingTokens.xl),

                      // 3. Totals
                      _MultiCurrencyFooter(output: state.output),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              if (state.isExporting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── CHARTS CAROUSEL (World Class UI) ─────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _BalanceSheetChartsCarousel extends StatefulWidget {
  const _BalanceSheetChartsCarousel({required this.output});
  final BalanceSheetOutput output;

  @override
  State<_BalanceSheetChartsCarousel> createState() =>
      _BalanceSheetChartsCarouselState();
}

class _BalanceSheetChartsCarouselState
    extends State<_BalanceSheetChartsCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sections = widget.output.currencySections.values.toList();
    if (sections.isEmpty) return const SizedBox.shrink();

    final currentSection = sections[_currentIndex];

    return Column(
      children: [
        // Tab selectors if multiple currencies
        if (sections.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(sections.length, (index) {
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(CurrencyUtil.getLocalizedName(
                            sections[index].currencyCode)
                        .replaceAll('﷼', AppStrings.sar)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _currentIndex = index);
                    },
                    selectedColor: ColorTokens.navy800,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : ColorTokens.navy900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ),
          ),
        if (sections.length > 1) SizedBox(height: 16),

        _FinancialHeaderChartCard(section: currentSection),
      ],
    );
  }
}

class _FinancialHeaderChartCard extends StatelessWidget {
  const _FinancialHeaderChartCard({required this.section});
  final BalanceSheetCurrencySectionDto section;

  double _minorToMajor(int minor, int digits) {
    double d = 1;
    for (var i = 0; i < digits; i++) {
      d *= 10;
    }
    return minor / d;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qayd = Theme.of(context).extension<QaydCustomColors>()!;

    final assets =
        _minorToMajor(section.totalAssetsMinorUnits, section.currencyDigits);
    final liabilities = -_minorToMajor(
        section.totalLiabilitiesMinorUnits, section.currencyDigits);
    final equity =
        -_minorToMajor(section.totalEquityMinorUnits, section.currencyDigits);

    final maxVal =
        [assets, liabilities, equity].reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.navy900.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: qayd.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: qayd.goldAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '${AppStrings.financialCenterPrefix}${CurrencyUtil.getLocalizedName(section.currencyCode).replaceAll('﷼', AppStrings.sar)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.navy900,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Bar Chart (Assets vs Liabilities vs Equity)
                Expanded(
                  flex: 2,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600);
                              Widget text;
                              switch (value.toInt()) {
                                case 0:
                                  text = Text(AppStrings.assetsLabel,
                                      style: style);
                                  break;
                                case 1:
                                  text = Text(AppStrings.liabilitiesLabel,
                                      style: style);
                                  break;
                                case 2:
                                  text = Text(AppStrings.equityLabel,
                                      style: style);
                                  break;
                                default:
                                  text = Text('');
                                  break;
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: text,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  _compactFormat(value),
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withAlpha(30),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _buildBarGroup(0, assets, ColorTokens.navy700),
                        _buildBarGroup(1, liabilities, qayd.goldAccent),
                        _buildBarGroup(2, equity, ColorTokens.emerald600),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 24),
                // Summary column
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendIndicator(
                          AppStrings.assetsLabel, assets, ColorTokens.navy700),
                      SizedBox(height: 12),
                      _buildLegendIndicator(AppStrings.liabilitiesLabel,
                          liabilities, qayd.goldAccent),
                      SizedBox(height: 12),
                      _buildLegendIndicator(AppStrings.equityLabel, equity,
                          ColorTokens.emerald600),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          _currencyFormat(value),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ColorTokens.navy900.withAlpha(200),
          ),
        ),
      ],
    );
  }

  String _compactFormat(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _currencyFormat(double value) {
    if (value == 0) return '0.00';
    return value.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── LEDGER TABLE (Merged Fields) ─────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _BalanceSheetLedger extends StatelessWidget {
  const _BalanceSheetLedger({required this.output});
  final BalanceSheetOutput output;

  @override
  Widget build(BuildContext context) {
    final assets =
        output.lines.where((l) => _isAsset(l.classification)).toList();
    final liab =
        output.lines.where((l) => _isLiability(l.classification)).toList();
    final equity =
        output.lines.where((l) => _isEquity(l.classification)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionGroup(AppStrings.assetsLabel, assets, context),
        SizedBox(height: 16),
        _buildSectionGroup(AppStrings.liabilitiesLabel, liab, context,
            shouldNegate: true),
        SizedBox(height: 16),
        _buildSectionGroup(AppStrings.equityLabel, equity, context,
            shouldNegate: true),
      ],
    );
  }

  Widget _buildSectionGroup(
      String title, List<BalanceSheetLineDto> lines, BuildContext context,
      {bool shouldNegate = false}) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final groups = _groupLines(lines);

    final scheme = Theme.of(context).colorScheme;
    // final qayd = Theme.of(context).extension<QaydCustomColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: ColorTokens.navy900,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ColorTokens.navy700,
            border: Border(
              bottom: BorderSide(color: ColorTokens.navy900.withAlpha(50)),
              left: BorderSide(color: ColorTokens.navy900.withAlpha(50)),
              right: BorderSide(color: ColorTokens.navy900.withAlpha(50)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Text(AppStrings.accountLabel, style: _headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(AppStrings.currencyLabel, style: _headerStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(AppStrings.accountBalanceLabel,
                    style: _headerStyle, textAlign: TextAlign.end),
              ),
            ],
          ),
        ),

        // Grouped Data Rows
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant),
              left: BorderSide(color: scheme.outlineVariant),
              right: BorderSide(color: scheme.outlineVariant),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: groups
                .map((g) => _AccountGroupItem(group: g, negate: shouldNegate))
                .toList(),
          ),
        ),
      ],
    );
  }

  TextStyle get _headerStyle => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ColorTokens.slate200,
      );

  List<_BSAccountGroup> _groupLines(List<BalanceSheetLineDto> lines) {
    final groups = <_BSAccountGroup>[];
    _BSAccountGroup? current;
    for (final line in lines) {
      if (current != null && current.accountId == line.accountId) {
        current.currencyLines.add(line);
      } else {
        current = _BSAccountGroup(
          accountId: line.accountId,
          accountCode: line.accountCode,
          accountName: line.accountName,
          level: line.level,
          isParent: line.isParent,
          currencyLines: [line],
        );
        groups.add(current);
      }
    }
    return groups;
  }

  static bool _isAsset(AccountClassification c) =>
      c == AccountClassification.liquidAssets ||
      c == AccountClassification.receivables ||
      c == AccountClassification.fixedProfitableAssets ||
      c == AccountClassification.fixedDepreciableAssets;

  static bool _isLiability(AccountClassification c) =>
      c == AccountClassification.payables ||
      c == AccountClassification.settlements ||
      c == AccountClassification.clearingRemittances;

  static bool _isEquity(AccountClassification c) =>
      c == AccountClassification.personalExpenses ||
      c == AccountClassification.personalRevenues ||
      c == AccountClassification.remittanceFees;
}

class _BSAccountGroup {
  _BSAccountGroup({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.level,
    required this.isParent,
    required this.currencyLines,
  });
  final String accountId;
  final String accountCode;
  final String accountName;
  final int level;
  final bool isParent;
  final List<BalanceSheetLineDto> currencyLines;
}

// ── Merged Row ───────────────────────────────────────────────────────────────

class _AccountGroupItem extends StatelessWidget {
  const _AccountGroupItem({required this.group, this.negate = false});
  final _BSAccountGroup group;
  final bool negate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBold = group.isParent;
    final weight = isBold ? FontWeight.w700 : FontWeight.w400;

    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: isBold
              ? scheme.surfaceContainerHighest.withAlpha(100)
              : scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Account Name & Code (Merged Cell) ──
            Expanded(
              flex: 6,
              child: Container(
                padding: EdgeInsets.only(
                  right: 16 + (group.level * 16).toDouble(),
                  left: 16,
                  top: 10,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  border:
                      Border(left: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.accountCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.only(left: 8, top: 1),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          group.accountCode,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        group.accountName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: weight,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Currencies Sub-rows ──
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: group.currencyLines.asMap().entries.map((e) {
                  final i = e.key;
                  final line = e.value;
                  final isLast = i == group.currencyLines.length - 1;

                  final cur = CurrencyCode(
                    code: line.currencyCode,
                    nameAr: '',
                    symbol: line.currencySymbol,
                    fractionalDigits: line.currencyDigits,
                  );

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: isLast
                            ? BorderSide.none
                            : BorderSide(
                                color: scheme.outlineVariant.withAlpha(100)),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        color: scheme.outlineVariant)),
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ColorTokens.navy800.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    CurrencyUtil.getLocalizedName(
                                            line.currencyCode)
                                        .replaceAll('﷼', AppStrings.sar),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: ColorTokens.navy900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              alignment: AlignmentDirectional.centerEnd,
                              child: _MoneyText(
                                  negate
                                      ? -line.balanceMinorUnits
                                      : line.balanceMinorUnits,
                                  cur,
                                  weight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _MoneyText(int minorUnits, CurrencyCode cur, FontWeight weight) {
    if (minorUnits == 0) {
      return Text('—', style: TextStyle(color: Colors.grey.withAlpha(150)));
    }
    return QaydMoneyDisplay(
      money: Money.fromMinorUnits(minorUnits.abs(), cur),
      displayNegative: minorUnits < 0,
      size: QaydMoneyDisplaySize.small,
      fontWeight: weight,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── FOOTER ───────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _MultiCurrencyFooter extends StatelessWidget {
  const _MultiCurrencyFooter({required this.output});
  final BalanceSheetOutput output;

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
  final BalanceSheetCurrencySectionDto section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                Expanded(
                  child: Text(
                    '${AppStrings.totalsSummaryPrefix}${CurrencyUtil.getLocalizedName(section.currencyCode).replaceAll('﷼', AppStrings.sar)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: ColorTokens.navy900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(50)),
                  ),
                  child: Text(
                    balanced
                        ? AppStrings.balancedLabel
                        : AppStrings.unbalancedLabel,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow(
                    AppStrings.totalAssetsLabel,
                    section.totalAssetsMinorUnits,
                    currency,
                    ColorTokens.navy800),
                SizedBox(height: 8),
                _SummaryRow(
                    AppStrings.totalLiabilitiesLabel,
                    -section.totalLiabilitiesMinorUnits,
                    currency,
                    ColorTokens.navy800),
                SizedBox(height: 8),
                _SummaryRow(
                    AppStrings.equityLabel,
                    -section.totalEquityMinorUnits,
                    currency,
                    ColorTokens.navy800),
                SizedBox(height: 12),
                const Divider(height: 1),
                SizedBox(height: 12),
                _SummaryRow(
                  AppStrings.netLiabilitiesAndEquityLabel,
                  -(section.totalLiabilitiesMinorUnits +
                      section.totalEquityMinorUnits),
                  currency,
                  ColorTokens.navy900,
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
  const _SummaryRow(this.label, this.minorUnits, this.cur, this.color,
      {this.isBold = false});

  final String label;
  final int minorUnits;
  final CurrencyCode cur;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 12 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        QaydMoneyDisplay(
          money: Money.fromMinorUnits(minorUnits.abs(), cur),
          displayNegative: minorUnits < 0,
          size:
              isBold ? QaydMoneyDisplaySize.medium : QaydMoneyDisplaySize.small,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
        ),
      ],
    );
  }
}
