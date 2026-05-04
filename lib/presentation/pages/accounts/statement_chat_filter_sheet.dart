import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/di/injection_container.dart';

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
  String? _ccId;
  String? _ccName;
  bool _includePrevBalance = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _agreement = i.agreementStatus;
    _type = i.type;
    _from = i.fromDate;
    _to = i.toDate;
    _ccId = i.costCenterId;
    _includePrevBalance = i.includePreviousBalance;
    _loadCostCenterName();
  }

  Future<void> _loadCostCenterName() async {
    if (_ccId == null) return;
    final res =
        await InjectionContainer.getCostCenterDetailsUseCase.call(_ccId!);
    res.fold(
      (_) {},
      (dto) {
        if (mounted) setState(() => _ccName = dto.center.name);
      },
    );
  }

  StatementChatFilterInput _buildResult() {
    return StatementChatFilterInput(
      agreementStatus: _agreement,
      type: _type,
      fromDate: _from,
      toDate: _to,
      costCenterId: _ccId,
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

  Widget _agreementChips() {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        FilterChip(
          label: Text(AppStrings.voucherFilterStateAny),
          selected: _agreement == null,
          onSelected: (_) => setState(() => _agreement = null),
        ),
        FilterChip(
          label: Text(AppStrings.statementStatusConfirmed),
          selected: _agreement == AgreementStatus.accepted,
          onSelected: (_) => setState(
            () => _agreement = AgreementStatus.accepted,
          ),
          selectedColor: custom.confirmedState.withValues(alpha: 0.18),
          checkmarkColor: custom.confirmedState,
        ),
        FilterChip(
          label: Text(AppStrings.statementStatusPending),
          selected: _agreement == AgreementStatus.underRequest,
          onSelected: (_) => setState(
            () => _agreement = AgreementStatus.underRequest,
          ),
          selectedColor: custom.draftState.withValues(alpha: 0.18),
          checkmarkColor: custom.draftState,
        ),
        FilterChip(
          label: Text(AppStrings.statementStatusRejected),
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
                AppStrings.statementFilterTitle,
                slot: QaydTextStyleSlot.titleLarge,
              ),
            ),

            // ── Agreement Status (Color) ──
            _sectionTitle(AppStrings.statementFilterStatusSection),
            _agreementChips(),

            // ── Type ──
            _sectionTitle(AppStrings.voucherFilterTypeSection),
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

            // ── Brought Forward Balance Toggle ──
            if (_from != null) ...[
              SizedBox(height: SpacingTokens.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: QaydText(
                  AppStrings.statementIncludePreviousBalance,
                  slot: QaydTextStyleSlot.bodyMedium,
                ),
                subtitle: QaydText(
                  AppStrings.statementIncludePreviousBalanceHint,
                  slot: QaydTextStyleSlot.bodySmall,
                ),
                value: _includePrevBalance,
                onChanged: (v) => setState(() => _includePrevBalance = v),
              ),
            ],

            // ── Cost Center ──
            _sectionTitle(AppStrings.costCenter),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: QaydText(
                AppStrings.filterByCostCenter,
                slot: QaydTextStyleSlot.bodyMedium,
              ),
              subtitle: QaydText(
                _ccName ?? AppStrings.voucherFilterNotSelected,
                slot: QaydTextStyleSlot.bodySmall,
              ),
              trailing: Icon(
                _ccId != null
                    ? Icons.check_circle_rounded
                    : Icons.chevron_left_rounded,
                color: _ccId != null ? ColorTokens.emerald600 : null,
              ),
              onTap: () async {
                final res =
                    await InjectionContainer.listCostCentersUseCase.call();
                res.fold(
                  (_) {},
                  (centers) async {
                    if (!mounted) return;
                    final picked = await showModalBottomSheet<CostCenter>(
                      context: context,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QaydText(AppStrings.selectCostCenter,
                                slot: QaydTextStyleSlot.titleMedium),
                            SizedBox(height: SpacingTokens.md),
                            ...centers.map((c) => ListTile(
                                  title: Text(c.name),
                                  leading: Icon(
                                      Icons.pie_chart_outline_rounded),
                                  onTap: () => Navigator.pop(ctx, c),
                                )),
                            SizedBox(height: SpacingTokens.xl),
                          ],
                        ),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _ccId = picked.id;
                        _ccName = picked.name;
                      });
                    }
                  },
                );
              },
            ),

            // ── Actions ──
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _agreement = null;
                      _type = null;
                      _from = null;
                      _to = null;
                      _ccId = null;
                      _ccName = null;
                      _includePrevBalance = false;
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
