import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Filter sheet strictly for the professional financial Ledger
/// used in Management pages like IncomeStreamDetailPage.
Future<StatementChatFilterInput?> showLedgerFilterSheet(
  BuildContext context, {
  required StatementChatFilterInput initial,
}) {
  return showModalBottomSheet<StatementChatFilterInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _LedgerFilterBody(initial: initial),
  );
}

class _LedgerFilterBody extends StatefulWidget {
  const _LedgerFilterBody({required this.initial});
  final StatementChatFilterInput initial;

  @override
  State<_LedgerFilterBody> createState() => _LedgerFilterBodyState();
}

class _LedgerFilterBodyState extends State<_LedgerFilterBody> {
  VoucherType? _type;
  DateTime? _from;
  DateTime? _to;
  bool _includePrevBalance = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _type = i.type;
    _from = i.fromDate;
    _to = i.toDate;
    _includePrevBalance = i.includePreviousBalance;
  }

  StatementChatFilterInput _buildResult() {
    return StatementChatFilterInput(
      type: _type,
      fromDate: _from,
      toDate: _to,
      includePreviousBalance: _includePrevBalance,
      // We don't filter by agreement status natively here unless explicitly done
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? _to ?? now) : (_to ?? _from ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('en'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(_from!)) _to = _from;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(_to!)) _from = _to;
      }
    });
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: SpacingTokens.md,
        bottom: SpacingTokens.xs,
      ),
      child: QaydText(text, slot: QaydTextStyleSlot.labelLarge),
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        FilterChip(
          label: Text(AppStrings.voucherFilterTypeAny),
          selected: _type == null,
          onSelected: (_) => setState(() => _type = null),
        ),
        FilterChip(
          label: Text(AppStrings.voucherTypeReceipt),
          selected: _type == VoucherType.receipt,
          onSelected: (_) => setState(() => _type = VoucherType.receipt),
        ),
        FilterChip(
          label: Text(AppStrings.voucherTypePayment),
          selected: _type == VoucherType.payment,
          onSelected: (_) => setState(() => _type = VoucherType.payment),
        ),
      ],
    );
  }

  Widget _quickDateButtons() {
    final now = DateTime.now();
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        ActionChip(
          label: Text(AppStrings.statementDateThisMonth),
          onPressed: () => setState(() {
            _from = DateTime(now.year, now.month, 1);
            _to = now;
          }),
        ),
        ActionChip(
          label: Text(AppStrings.statementDateLastQuarter),
          onPressed: () {
            final qStart =
                DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1 - 3, 1);
            final qEnd = DateTime(qStart.year, qStart.month + 3, 0);
            setState(() {
              _from = qStart.isBefore(DateTime(2000)) ? DateTime(2000) : qStart;
              _to = qEnd;
            });
          },
        ),
        ActionChip(
          label: Text(AppStrings.statementDateThisYear),
          onPressed: () => setState(() {
            _from = DateTime(now.year, 1, 1);
            _to = now;
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final df = DateFormat.yMMMd('en');
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: SpacingTokens.md,
        right: SpacingTokens.md,
        bottom: bottomInset + SpacingTokens.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: QaydText(
                AppStrings.filterTheFinancialRecord,
                slot: QaydTextStyleSlot.titleLarge,
              ),
            ),

            // ── Type ──
            _sectionTitle(AppStrings.typeOfFinancialTransaction),
            _typeChips(),

            // ── Date Range ──
            _sectionTitle(AppStrings.voucherFilterDateSection),
            _quickDateButtons(),
            SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: QaydText(
                      AppStrings.voucherFilterDateFrom,
                      slot: QaydTextStyleSlot.bodyMedium,
                    ),
                    subtitle: QaydText(
                      _from != null
                          ? df.format(_from!)
                          : AppStrings.voucherFilterDateNotSet,
                      slot: QaydTextStyleSlot.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                    ),
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: QaydText(
                      AppStrings.voucherFilterDateTo,
                      slot: QaydTextStyleSlot.bodyMedium,
                    ),
                    subtitle: QaydText(
                      _to != null
                          ? df.format(_to!)
                          : AppStrings.voucherFilterDateNotSet,
                      slot: QaydTextStyleSlot.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                    ),
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),

            // ── Actions ──
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _type = null;
                      _from = null;
                      _to = null;
                      _includePrevBalance = true;
                    }),
                    child: Text(AppStrings.voucherFilterClearFields),
                  ),
                ),
                SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: ColorTokens.navy950,
                    ),
                    onPressed: () => Navigator.of(context).pop(_buildResult()),
                    child: Text(AppStrings.voucherFilterApply),
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
