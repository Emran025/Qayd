import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';

/// Premium filter sheet; returns new [AdvancedFilterInput] on apply, or null if dismissed.
Future<AdvancedFilterInput?> showVoucherAdvancedFilterSheet(
  BuildContext context, {
  required AdvancedFilterInput initial,
  required Map<String, String> accountNamesById,
  required ListAccountsUseCase listAccounts,
}) {
  return showModalBottomSheet<AdvancedFilterInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _VoucherFilterSheetBody(
      initial: initial,
      accountNamesById: accountNamesById,
      listAccounts: listAccounts,
    ),
  );
}

class _VoucherFilterSheetBody extends StatefulWidget {
  const _VoucherFilterSheetBody({
    required this.initial,
    required this.accountNamesById,
    required this.listAccounts,
  });

  final AdvancedFilterInput initial;
  final Map<String, String> accountNamesById;
  final ListAccountsUseCase listAccounts;

  @override
  State<_VoucherFilterSheetBody> createState() =>
      _VoucherFilterSheetBodyState();
}

class _VoucherFilterSheetBodyState extends State<_VoucherFilterSheetBody> {
  VoucherType? _type;
  VoucherState? _state;
  DateTime? _from;
  DateTime? _to;
  String? _cpId;
  String? _cpName;
  String? _affId;
  String? _affName;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _type = i.type;
    _state = i.state;
    _from = i.fromDate;
    _to = i.toDate;
    final cp = i.counterpartyAccountId?.trim();
    _cpId = (cp == null || cp.isEmpty) ? null : cp;
    _cpName = _cpId != null
        ? (widget.accountNamesById[_cpId!] ?? _cpId)
        : null;
    final aff = i.affectedAccountId?.trim();
    _affId = (aff == null || aff.isEmpty) ? null : aff;
    _affName = _affId != null
        ? (widget.accountNamesById[_affId!] ?? _affId)
        : null;
  }

  AdvancedFilterInput _buildResult() {
    return AdvancedFilterInput(
      type: _type,
      state: _state,
      fromDate: _from,
      toDate: _to,
      counterpartyAccountId: _cpId,
      affectedAccountId: _affId,
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
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(_from!)) {
          _to = _from;
        }
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(_to!)) {
          _from = _to;
        }
      }
    });
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.md, bottom: SpacingTokens.xs),
      child: QaydText(
        text,
        slot: QaydTextStyleSlot.labelLarge,
      ),
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
          onSelected: (_) =>
              setState(() => _type = VoucherType.receipt),
        ),
        FilterChip(
          label: Text(AppStringsAr.voucherTypePayment),
          selected: _type == VoucherType.payment,
          onSelected: (_) =>
              setState(() => _type = VoucherType.payment),
        ),
      ],
    );
  }

  Widget _stateChips() {
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        FilterChip(
          label: Text(AppStringsAr.voucherFilterStateAny),
          selected: _state == null,
          onSelected: (_) => setState(() => _state = null),
        ),
        FilterChip(
          label: Text(AppStringsAr.voucherStateDraft),
          selected: _state == VoucherState.draft,
          onSelected: (_) =>
              setState(() => _state = VoucherState.draft),
        ),
        FilterChip(
          label: Text(AppStringsAr.voucherStateConfirmed),
          selected: _state == VoucherState.confirmed,
          onSelected: (_) =>
              setState(() => _state = VoucherState.confirmed),
        ),
        FilterChip(
          label: Text(AppStringsAr.voucherStateSettled),
          selected: _state == VoucherState.settled,
          onSelected: (_) =>
              setState(() => _state = VoucherState.settled),
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
                AppStringsAr.voucherFilterSheetTitle,
                slot: QaydTextStyleSlot.titleLarge,
              ),
            ),
            _sectionTitle(AppStringsAr.voucherFilterTypeSection),
            _typeChips(),
            _sectionTitle(AppStringsAr.voucherFilterStateSection),
            _stateChips(),
            _sectionTitle(AppStringsAr.voucherFilterDateSection),
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
                      _from != null ? df.format(_from!) : AppStringsAr.voucherFilterDateNotSet,
                      slot: QaydTextStyleSlot.bodySmall,
                    ),
                    trailing: const Icon(Icons.calendar_month_rounded, size: 20),
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
                      _to != null ? df.format(_to!) : AppStringsAr.voucherFilterDateNotSet,
                      slot: QaydTextStyleSlot.bodySmall,
                    ),
                    trailing: const Icon(Icons.calendar_month_rounded, size: 20),
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            _sectionTitle(AppStringsAr.voucherFilterAccountsSection),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: QaydText(
                AppStringsAr.voucherCounterpartyLabel,
                slot: QaydTextStyleSlot.bodyMedium,
              ),
              subtitle: QaydText(
                _cpName ?? AppStringsAr.voucherFilterNotSelected,
                slot: QaydTextStyleSlot.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                _cpId != null ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
                color: _cpId != null ? ColorTokens.emerald600 : null,
              ),
              onTap: () async {
                final a = await showAccountPickerSheet(
                  context,
                  listAccounts: widget.listAccounts,
                  excludeAccountId: _affId,
                );
                if (a != null && mounted) {
                  setState(() {
                    _cpId = a.id;
                    _cpName = a.name;
                  });
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: QaydText(
                AppStringsAr.voucherAffectedAccountLabel,
                slot: QaydTextStyleSlot.bodyMedium,
              ),
              subtitle: QaydText(
                _affName ?? AppStringsAr.voucherFilterNotSelected,
                slot: QaydTextStyleSlot.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                _affId != null ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
                color: _affId != null ? ColorTokens.emerald600 : null,
              ),
              onTap: () async {
                final a = await showAccountPickerSheet(
                  context,
                  listAccounts: widget.listAccounts,
                  excludeAccountId: _cpId,
                );
                if (a != null && mounted) {
                  setState(() {
                    _affId = a.id;
                    _affName = a.name;
                  });
                }
              },
            ),
            const SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _type = null;
                        _state = null;
                        _from = null;
                        _to = null;
                        _cpId = null;
                        _cpName = null;
                        _affId = null;
                        _affName = null;
                      });
                    },
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
