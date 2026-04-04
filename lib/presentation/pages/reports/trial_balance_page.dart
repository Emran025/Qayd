import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';
import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_cubit.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_state.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

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
    return QaydScaffold(
      appBar: QaydAppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppStringsAr.trialBalanceTitle,
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
        ],
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TrialBalanceCubit>().load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: _TrialBalanceTable(output: output),
        ),
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

    final grouped = <String, List<TrialBalanceLineDto>>{};
    for (final line in output.lines) {
      if (line.debitMinorUnits == 0 && line.creditMinorUnits == 0) continue;
      grouped.putIfAbsent(line.accountName, () => []).add(line);
    }
    if (grouped.isEmpty && output.lines.isNotEmpty) {
      for (final line in output.lines) {
        grouped.putIfAbsent(line.accountName, () => []).add(line);
      }
    }

    return grouped.entries.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: QaydText(
                AppStringsAr.trialBalanceEmpty,
                slot: QaydTextStyleSlot.bodyLarge,
                textAlign: TextAlign.center,
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.sm,
              SpacingTokens.sm,
              SpacingTokens.sm,
              SpacingTokens.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(12),
                      1: FlexColumnWidth(9),
                      2: FlexColumnWidth(5),
                    },
                    border: TableBorder.all(
                      color: scheme.outlineVariant,
                      width: 1,
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildHeaderRow(scheme),
                      for (final entry in grouped.entries)
                        _buildDataRow(context, entry.key, entry.value),
                    ],
                  ),
                ),
                const SizedBox(height: SpacingTokens.xl),
                _MultiCurrencyFooter(output: output),
              ],
            ),
          );
  }

  TableRow _buildHeaderRow(ColorScheme scheme) {
    return TableRow(
      decoration: BoxDecoration(color: scheme.tertiary),
      children: [
        _HeaderPadding(
          child: QaydText(
            AppStringsAr.trialBalanceColAccount,
            slot: QaydTextStyleSlot.labelMedium,
          ),
        ),
        _HeaderPadding(
          child: QaydText(
            AppStringsAr.accountBalanceLabel,
            slot: QaydTextStyleSlot.labelMedium,
          ),
        ),
        _HeaderPadding(
          child: QaydText('العملة', slot: QaydTextStyleSlot.labelMedium),
        ),
      ],
    );
  }

  TableRow _buildDataRow(
    BuildContext context,
    String accountName,
    List<TrialBalanceLineDto> lines,
  ) {
    final amounts = <Widget>[];
    final currencies = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final bool isDebit = line.debitMinorUnits > 0;
      final bool isCredit = line.creditMinorUnits > 0;
      final int amount = isDebit ? line.debitMinorUnits : line.creditMinorUnits;

      if (i > 0) {
        amounts.add(
          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1,
            thickness: 1,
          ),
        );
        currencies.add(
          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1,
            thickness: 1,
          ),
        );
      }

      Widget amountWidget;
      if (!isDebit && !isCredit) {
        amountWidget = QaydText(
          '—',
          slot: QaydTextStyleSlot.bodySmall,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      } else {
        amountWidget = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: QaydMoneyDisplay(
                money: Money.nonNegative(
                  amount,
                  CurrencyCode(
                    code: line.currencyCode,
                    nameAr: '',
                    symbol: line.currencySymbol,
                    fractionalDigits: line.currencyDigits,
                  ),
                ),
                size: QaydMoneyDisplaySize.small,
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDebit
                    ? ColorTokens.debitBlue.withValues(alpha: 0.15)
                    : ColorTokens.creditGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDebit
                      ? ColorTokens.debitBlue
                      : ColorTokens.creditGreen,
                ),
              ),
              child: QaydText(
                isDebit
                    ? AppStringsAr.natureDebitShort
                    : AppStringsAr.natureCreditShort,
                slot: QaydTextStyleSlot.labelSmall,
                color: isDebit
                    ? ColorTokens.debitBlue
                    : ColorTokens.creditGreen,
              ),
            ),
          ],
        );
      }

      amounts.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
          child: amountWidget,
        ),
      );

      currencies.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
          child: QaydText(
            line.currencyCode,
            slot: QaydTextStyleSlot.labelMedium,
          ),
        ),
      );
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: SpacingTokens.md,
          ),
          child: QaydText(
            accountName,
            slot: QaydTextStyleSlot.bodySmall,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: amounts,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: currencies,
          ),
        ),
      ],
    );
  }
}

class _HeaderPadding extends StatelessWidget {
  const _HeaderPadding({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm + 4,
      ),
      child: child,
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
