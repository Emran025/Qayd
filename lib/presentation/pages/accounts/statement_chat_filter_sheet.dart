import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Premium filter sheet for the Statement of Account chat.
/// Returns new [StatementChatFilterInput] on apply, or null if dismissed.
Future<StatementChatFilterInput?> showStatementChatFilterSheet(
  BuildContext context, {
  required StatementChatFilterInput initial,
}) {
  return showModalBottomSheet<StatementChatFilterInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _StatementFilterBody(initial: initial),
  );
}

class _StatementFilterBody extends StatefulWidget {
  const _StatementFilterBody({required this.initial});
  final StatementChatFilterInput initial;

  @override
  State<_StatementFilterBody> createState() => _StatementFilterBodyState();
}

class _StatementFilterBodyState extends State<_StatementFilterBody> {
  AgreementStatus? _agreement;
  VoucherType? _type;
  DateTime? _from;
  DateTime? _to;
  bool _includePrevBalance = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _agreement = i.agreementStatus;
    _type = i.type;
    _from = i.fromDate;
    _to = i.toDate;
    _includePrevBalance = i.includePreviousBalance;
  }

  StatementChatFilterInput _buildResult() {
    return StatementChatFilterInput(
      agreementStatus: _agreement,
      type: _type,
      fromDate: _from,
      toDate: _to,
      includePreviousBalance: _includePrevBalance,
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
      locale: const Locale('ar'),
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

  Widget _agreementChips() {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        FilterChip(
          label: Text(AppStringsAr.voucherFilterStateAny),
          selected: _agreement == null,
          onSelected: (_) => setState(() => _agreement = null),
        ),
        FilterChip(
          label: Text(AppStringsAr.statementStatusConfirmed),
          selected: _agreement == AgreementStatus.accepted,
          onSelected: (_) => setState(
            () => _agreement = AgreementStatus.accepted,
          ),
          selectedColor: custom.confirmedState.withValues(alpha: 0.18),
          checkmarkColor: custom.confirmedState,
        ),
        FilterChip(
          label: Text(AppStringsAr.statementStatusPending),
          selected: _agreement == AgreementStatus.underRequest,
          onSelected: (_) => setState(
            () => _agreement = AgreementStatus.underRequest,
          ),
          selectedColor: custom.draftState.withValues(alpha: 0.18),
          checkmarkColor: custom.draftState,
        ),
        FilterChip(
          label: Text(AppStringsAr.statementStatusRejected),
          selected: _agreement == AgreementStatus.rejected,
          onSelected: (_) => setState(
            () => _agreement = AgreementStatus.rejected,
          ),
          selectedColor: ColorTokens.errorSoft.withValues(alpha: 0.18),
          checkmarkColor: ColorTokens.errorDeep,
        ),
      ],
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        FilterChip(
          label: Text(AppStringsAr.voucherFilterTypeAny),
          selected: _type == null,
          onSelected: (_) => setState(() => _type = null),
        ),
        FilterChip(
          label: Text(AppStringsAr.voucherTypeReceipt),
          selected: _type == VoucherType.receipt,
          onSelected: (_) => setState(() => _type = VoucherType.receipt),
        ),
        FilterChip(
          label: Text(AppStringsAr.voucherTypePayment),
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
          label: Text(AppStringsAr.statementDateThisMonth),
          onPressed: () => setState(() {
            _from = DateTime(now.year, now.month, 1);
            _to = now;
          }),
        ),
        ActionChip(
          label: Text(AppStringsAr.statementDateLastQuarter),
          onPressed: () {
            final qStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1 - 3, 1);
            final qEnd = DateTime(qStart.year, qStart.month + 3, 0);
            setState(() {
              _from = qStart.isBefore(DateTime(2000)) ? DateTime(2000) : qStart;
              _to = qEnd;
            });
          },
        ),
        ActionChip(
          label: Text(AppStringsAr.statementDateThisYear),
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
    final df = DateFormat.yMMMd('ar');
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
                AppStringsAr.statementFilterTitle,
                slot: QaydTextStyleSlot.titleLarge,
              ),
            ),

            // ── Agreement Status (Color) ──
            _sectionTitle(AppStringsAr.statementFilterStatusSection),
            _agreementChips(),

            // ── Type ──
            _sectionTitle(AppStringsAr.voucherFilterTypeSection),
            _typeChips(),

            // ── Date Range ──
            _sectionTitle(AppStringsAr.voucherFilterDateSection),
            _quickDateButtons(),
            const SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: QaydText(
                      AppStringsAr.voucherFilterDateFrom,
                      slot: QaydTextStyleSlot.bodyMedium,
                    ),
                    subtitle: QaydText(
                      _from != null
                          ? df.format(_from!)
                          : AppStringsAr.voucherFilterDateNotSet,
                      slot: QaydTextStyleSlot.bodySmall,
                    ),
                    trailing: const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                    ),
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: QaydText(
                      AppStringsAr.voucherFilterDateTo,
                      slot: QaydTextStyleSlot.bodyMedium,
                    ),
                    subtitle: QaydText(
                      _to != null
                          ? df.format(_to!)
                          : AppStringsAr.voucherFilterDateNotSet,
                      slot: QaydTextStyleSlot.bodySmall,
                    ),
                    trailing: const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                    ),
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),

            // ── Brought Forward Balance Toggle ──
            if (_from != null) ...[
              const SizedBox(height: SpacingTokens.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: QaydText(
                  AppStringsAr.statementIncludePreviousBalance,
                  slot: QaydTextStyleSlot.bodyMedium,
                ),
                subtitle: QaydText(
                  AppStringsAr.statementIncludePreviousBalanceHint,
                  slot: QaydTextStyleSlot.bodySmall,
                ),
                value: _includePrevBalance,
                onChanged: (v) => setState(() => _includePrevBalance = v),
              ),
            ],

            // ── Actions ──
            const SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _agreement = null;
                      _type = null;
                      _from = null;
                      _to = null;
                      _includePrevBalance = false;
                    }),
                    child: Text(AppStringsAr.voucherFilterClearFields),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: ColorTokens.navy950,
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(_buildResult()),
                    child: Text(AppStringsAr.voucherFilterApply),
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
