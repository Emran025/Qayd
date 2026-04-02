import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';
import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_cubit.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_state.dart';
import 'package:qayd/presentation/pages/settings/settings_app_bar_action.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class TrialBalancePage extends StatelessWidget {
  const TrialBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TrialBalanceCubit(InjectionContainer.generateTrialBalanceUseCase)
            ..load(),
      child: const _TrialBalanceView(),
    );
  }
}

class _TrialBalanceView extends StatelessWidget {
  const _TrialBalanceView();

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      appBar: AppBar(
        title: QaydText(
          AppStringsAr.trialBalanceTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        actions: [
          BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
            builder: (context, state) {
              return IconButton(
                tooltip: AppStringsAr.refreshBalanceTooltip,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: state is TrialBalanceLoading
                    ? null
                    : () => context.read<TrialBalanceCubit>().load(),
              );
            },
          ),
          const SettingsAppBarAction(),
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
      body: BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
        builder: (context, state) {
          return switch (state) {
            TrialBalanceInitial() => const SizedBox.shrink(),
            TrialBalanceLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TrialBalanceFailure(:final failure) => Center(
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
                      onPressed: () => context.read<TrialBalanceCubit>().load(),
                      child: Text(AppStringsAr.retryAction),
                    ),
                  ],
                ),
              ),
            ),
            TrialBalanceReady(:final output) => _TrialBalanceBody(
              output: output,
            ),
          };
        },
      ),
    );
  }
}

class _TrialBalanceBody extends StatelessWidget {
  const _TrialBalanceBody({required this.output});

  final TrialBalanceOutput output;

  static const double _minTableWidth = 520;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TrialBalanceCubit>().load(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = _TrialBalanceTable(output: output);
          if (constraints.maxWidth < _minTableWidth) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _minTableWidth,
                  height: constraints.maxHeight,
                  child: table,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: table,
            ),
          );
        },
      ),
    );
  }
}

class _TrialBalanceTable extends StatelessWidget {
  const _TrialBalanceTable({required this.output});

  final TrialBalanceOutput output;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TableHeaderRow(scheme: scheme),
          const SizedBox(height: SpacingTokens.xs),
          ..._buildCurrencySections(context),
          const SizedBox(height: SpacingTokens.md),
          _MultiCurrencyFooter(output: output),
        ],
      ),
    );
  }

  List<Widget> _buildCurrencySections(BuildContext context) {
    final grouped = <String, List<TrialBalanceLineDto>>{};
    for (final line in output.lines) {
      grouped.putIfAbsent(line.currencyCode, () => []).add(line);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      if (grouped.length > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            child: QaydText(
              'العملة: ${entry.key}',
              slot: QaydTextStyleSlot.titleSmall,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      widgets.addAll(
        List.generate(
          entry.value.length,
          (i) => _DataRow(line: entry.value[i], stripe: i.isOdd),
        ),
      );
    }
    return widgets;
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: QaydText(
              AppStringsAr.trialBalanceColAccount,
              slot: QaydTextStyleSlot.labelLarge,
            ),
          ),
          Expanded(
            flex: 7,
            child: QaydText(
              AppStringsAr.trialBalanceColDebit,
              slot: QaydTextStyleSlot.labelLarge,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 7,
            child: QaydText(
              AppStringsAr.trialBalanceColCredit,
              slot: QaydTextStyleSlot.labelLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.line, required this.stripe});

  final TrialBalanceLineDto line;
  final bool stripe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = stripe
        ? scheme.surfaceContainerLow.withValues(alpha: 0.65)
        : Colors.transparent;

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 11,
              child: QaydText(
                line.accountName,
                slot: QaydTextStyleSlot.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 7,
              child: _MoneyCell(
                minorUnits: line.debitMinorUnits,
                currency: CurrencyCode(
                  code: line.currencyCode,
                  nameAr: '',
                  symbol: line.currencySymbol,
                  fractionalDigits: line.currencyDigits,
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: _MoneyCell(
                minorUnits: line.creditMinorUnits,
                currency: CurrencyCode(
                  code: line.currencyCode,
                  nameAr: '',
                  symbol: line.currencySymbol,
                  fractionalDigits: line.currencyDigits,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyCell extends StatelessWidget {
  const _MoneyCell({required this.minorUnits, required this.currency});

  final int minorUnits;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    if (minorUnits == 0) {
      return QaydText(
        '—',
        slot: QaydTextStyleSlot.bodyMedium,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        textAlign: TextAlign.end,
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: QaydMoneyDisplay(
        money: Money.nonNegative(minorUnits, currency),
        size: QaydMoneyDisplaySize.small,
        textAlign: TextAlign.end,
      ),
    );
  }
}

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
    final emerald = ColorTokens.emerald600;
    final currency = CurrencyCode(
      code: section.currencyCode,
      nameAr: '',
      symbol: section.currencySymbol,
      fractionalDigits: section.currencyDigits,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 11,
                  child: QaydText(
                    '${AppStringsAr.trialBalanceGrandTotal} (${section.currencyCode})',
                    slot: QaydTextStyleSlot.titleSmall,
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: QaydMoneyDisplay(
                      money: Money.nonNegative(
                        section.totalDebitMinorUnits,
                        currency,
                      ),
                      size: QaydMoneyDisplaySize.medium,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: QaydMoneyDisplay(
                      money: Money.nonNegative(
                        section.totalCreditMinorUnits,
                        currency,
                      ),
                      size: QaydMoneyDisplaySize.medium,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: SpacingTokens.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  section.isBalanced
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  size: 22,
                  color: section.isBalanced
                      ? emerald
                      : ColorTokens.warningAmber,
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QaydText(
                        section.isBalanced
                            ? AppStringsAr.trialBalanceBalanced
                            : AppStringsAr.trialBalanceNotBalanced,
                        slot: QaydTextStyleSlot.bodyMedium,
                        color: section.isBalanced ? emerald : scheme.error,
                      ),
                      if (!section.isBalanced) ...[
                        const SizedBox(height: SpacingTokens.xs),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: SpacingTokens.sm,
                          children: [
                            QaydText(
                              AppStringsAr.trialBalanceImbalanceLabel,
                              slot: QaydTextStyleSlot.bodySmall,
                              color: scheme.onSurfaceVariant,
                            ),
                            QaydMoneyDisplay(
                              money: Money.nonNegative(
                                section.imbalanceMinorUnits.abs(),
                                currency,
                              ),
                              size: QaydMoneyDisplaySize.small,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
