import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/fiscal_period.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/core/result/result.dart';

class FiscalPeriodsSettingsPage extends StatefulWidget {
  const FiscalPeriodsSettingsPage({super.key});

  @override
  State<FiscalPeriodsSettingsPage> createState() =>
      _FiscalPeriodsSettingsPageState();
}

class _FiscalPeriodsSettingsPageState extends State<FiscalPeriodsSettingsPage> {
  bool _loading = true;
  List<FiscalPeriod> _periods = const [];

  String _closingPolicy = 'manual';
  String _autoFrequency = 'monthly';
  DateTime? _autoStartDate;

  DateTime? _manualStartDate;
  DateTime? _manualEndDate;

  FiscalPeriod? get _openPeriod {
    for (final p in _periods) {
      if (p.status == FiscalPeriodStatus.open) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final r = await InjectionContainer.fiscalPeriodRepository.listAllOrdered();
    final prefs = InjectionContainer.sharedPreferences;
    _closingPolicy = prefs.getString('fiscal_closing_policy') ?? 'manual';
    _autoFrequency = prefs.getString('fiscal_auto_frequency') ?? 'monthly';
    final autoStartIso = prefs.getString('fiscal_auto_start_date');
    _autoStartDate = autoStartIso == null ? null : DateTime.tryParse(autoStartIso);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _periods = r.isSuccess ? r.valueOrNull! : const [];
      _manualStartDate ??= _defaultStartDate();
      _manualEndDate ??= _suggestEndDate(_manualStartDate!);
      _autoStartDate ??= _defaultStartDate();
    });
  }

  Future<void> _closePeriod(FiscalPeriod open) async {
    final confirm = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.lock_clock_rounded,
      title: AppStrings.fiscalPeriodCloseButton,
      content: AppStrings.fiscalPeriodCloseConfirm,
      primaryActionLabel: AppStrings.fiscalPeriodCloseButton,
      secondaryActionLabel: AppStrings.actionCancel,
      onPrimaryAction: () => Navigator.of(context).pop(true),
    );
    if (confirm != true || !mounted) return;

    final res = await InjectionContainer.closeFiscalPeriodUseCase.call(open.id);
    if (!mounted) return;
    if (res.isFailure) {
      _toast(res.failureOrNull!.messageAr);
      return;
    }
    _toast(AppStrings.finished);
    await _refresh();
  }

  Future<void> _approveAutomation() async {
    if (_autoStartDate == null) return;
    final prefs = InjectionContainer.sharedPreferences;
    await prefs.setString('fiscal_closing_policy', 'auto_periodic');
    await prefs.setString('fiscal_auto_frequency', _autoFrequency);
    await prefs.setString(
      'fiscal_auto_start_date',
      DateTime(
        _autoStartDate!.year,
        _autoStartDate!.month,
        _autoStartDate!.day,
      ).toIso8601String(),
    );
    if (_openPeriod == null) {
      final start = DateTime(
        _autoStartDate!.year,
        _autoStartDate!.month,
        _autoStartDate!.day,
      );
      final endExclusive = _nextBoundary(start, _autoFrequency);
      final end = endExclusive.subtract(const Duration(days: 1));
      final createR = await InjectionContainer.createFiscalPeriodUseCase.call(
        name: _nameForRange(start, end),
        startDate: start,
        endDate: end,
      );
      if (createR.isFailure && mounted) {
        _toast(createR.failureOrNull!.messageAr);
        return;
      }
    }
    InjectionContainer.autoFiscalClosingService?.start();
    if (!mounted) return;
    _toast(AppStrings.approved);
    setState(() => _closingPolicy = 'auto_periodic');
    await _refresh();
  }

  Future<void> _approveManualPeriod() async {
    if (_manualStartDate == null || _manualEndDate == null) return;
    if (_openPeriod != null) {
      _toast(AppStrings.fiscalPeriodOpenAlreadyExists);
      return;
    }
    if (_manualEndDate!.isBefore(_manualStartDate!)) {
      _toast(AppStrings.fiscalPeriodInvalidRange);
      return;
    }
    if (_hasOverlap(_manualStartDate!, _manualEndDate!)) {
      _toast(AppStrings.fiscalPeriodOverlap);
      return;
    }

    final name = _nameForRange(_manualStartDate!, _manualEndDate!);
    final res = await InjectionContainer.createFiscalPeriodUseCase(
      name: name,
      startDate: _manualStartDate!,
      endDate: _manualEndDate!,
    );
    if (!mounted) return;
    if (res.isFailure) {
      _toast(res.failureOrNull!.messageAr);
      return;
    }
    _toast(AppStrings.approved);
    await _refresh();
  }

  Future<void> _pickManualStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualStartDate ?? _defaultStartDate(),
      firstDate: _defaultStartDate(),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _manualStartDate = DateTime(picked.year, picked.month, picked.day);
      _manualEndDate = _suggestEndDate(_manualStartDate!);
    });
  }

  Future<void> _pickManualEnd() async {
    final start = _manualStartDate ?? _defaultStartDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualEndDate ?? _suggestEndDate(start),
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _manualEndDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickAutoStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _autoStartDate ?? _defaultStartDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _autoStartDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.fiscalPeriodsPageTitle),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(SpacingTokens.md),
                children: [
                  _buildPolicyCard(context),
                  const SizedBox(height: SpacingTokens.md),
                  if (_closingPolicy == 'auto_periodic')
                    _buildAutomationCard(context)
                  else
                    _buildManualCard(context),
                  const SizedBox(height: SpacingTokens.md),
                  _buildPeriodsList(context),
                ],
              ),
            ),
    );
  }

  Widget _buildPolicyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.fiscalPeriodPolicyLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SpacingTokens.sm),
            Semantics(
              label: AppStrings.fiscalPeriodPolicyLabel,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'manual',
                    label: Text(AppStrings.fiscalPeriodPolicyManual),
                    icon: const Icon(Icons.rule_folder_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'auto_periodic',
                    label: Text(AppStrings.fiscalPeriodPolicyAuto),
                    icon: const Icon(Icons.schedule_send_outlined),
                  ),
                ],
                selected: {_closingPolicy},
                onSelectionChanged: (set) async {
                  final next = set.first;
                  setState(() => _closingPolicy = next);
                  await InjectionContainer.sharedPreferences
                      .setString('fiscal_closing_policy', next);
                  if (next == 'auto_periodic') {
                    InjectionContainer.autoFiscalClosingService?.start();
                  } else {
                    InjectionContainer.autoFiscalClosingService?.stop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationCard(BuildContext context) {
    final df = DateFormat.yMMMd(AppStrings.languageCode);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.fiscalPeriodPolicyAuto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SpacingTokens.sm),
            DropdownButtonFormField<String>(
              value: _autoFrequency,
              decoration: InputDecoration(
                labelText: AppStrings.period,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'weekly', child: Text(AppStrings.weekly)),
                DropdownMenuItem(
                    value: 'monthly', child: Text(AppStrings.monthly)),
                DropdownMenuItem(
                    value: 'annually', child: Text(AppStrings.annually)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _autoFrequency = v);
              },
            ),
            const SizedBox(height: SpacingTokens.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.fiscalPeriodStartLabel),
              subtitle: Text(df.format(_autoStartDate ?? _defaultStartDate())),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickAutoStart,
            ),
            const SizedBox(height: SpacingTokens.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _approveAutomation,
                icon: const Icon(Icons.verified_outlined),
                label: Text(AppStrings.actionApprove),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCard(BuildContext context) {
    final open = _openPeriod;
    final df = DateFormat.yMMMd(AppStrings.languageCode);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.fiscalPeriodPolicyManual,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SpacingTokens.sm),
            if (open != null) ...[
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18),
                    const SizedBox(width: SpacingTokens.xs),
                    Expanded(
                      child: Text(
                        AppStrings.fiscalPeriodOpenAlreadyExists,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => _closePeriod(open),
                  child: Text(AppStrings.fiscalPeriodCloseButton),
                ),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.fiscalPeriodStartLabel),
                subtitle:
                    Text(df.format(_manualStartDate ?? _defaultStartDate())),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickManualStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.fiscalPeriodEndLabel),
                subtitle: Text(
                  df.format(
                    _manualEndDate ??
                        _suggestEndDate(_manualStartDate ?? _defaultStartDate()),
                  ),
                ),
                trailing: const Icon(Icons.event_available_outlined),
                onTap: _pickManualEnd,
              ),
              const SizedBox(height: SpacingTokens.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _approveManualPeriod,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(AppStrings.actionApprove),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodsList(BuildContext context) {
    if (_periods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: QaydText(
            AppStrings.fiscalPeriodEmpty,
            slot: QaydTextStyleSlot.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final df = DateFormat.yMMMd(AppStrings.languageCode);
    return Column(
      children: _periods.reversed.map((p) {
        final isOpen = p.status == FiscalPeriodStatus.open;
        final range = '${df.format(p.startDate)} — ${df.format(p.endDate)}';
        return Card(
          margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
          child: ListTile(
            title: Text(p.name),
            subtitle: Text(
              '$range\n${isOpen ? AppStrings.fiscalPeriodDividerOpen : AppStrings.fiscalPeriodDividerClosed}',
            ),
            isThreeLine: true,
            trailing: isOpen
                ? FilledButton.tonal(
                    onPressed: () => _closePeriod(p),
                    child: Text(AppStrings.fiscalPeriodCloseButton),
                  )
                : (p.aggregateSnapshotHash != null
                    ? Icon(
                        Icons.verified_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null),
          ),
        );
      }).toList(growable: false),
    );
  }

  DateTime _defaultStartDate() {
    DateTime? latestClosedEnd;
    for (final p in _periods) {
      if (p.status != FiscalPeriodStatus.closed) continue;
      final end = DateTime(p.endDate.year, p.endDate.month, p.endDate.day);
      if (latestClosedEnd == null || end.isAfter(latestClosedEnd)) {
        latestClosedEnd = end;
      }
    }
    if (latestClosedEnd == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, 1);
    }
    return latestClosedEnd.add(const Duration(days: 1));
  }

  DateTime _suggestEndDate(DateTime start) {
    return DateTime(start.year, start.month + 1, 0);
  }

  DateTime _nextBoundary(DateTime start, String frequency) {
    return switch (frequency) {
      'weekly' => start.add(const Duration(days: 7)),
      'annually' => DateTime(start.year + 1, start.month, start.day),
      _ => DateTime(start.year, start.month + 1, start.day),
    };
  }

  bool _hasOverlap(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    for (final p in _periods) {
      final ps = DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
      final pe = DateTime(p.endDate.year, p.endDate.month, p.endDate.day);
      if (!e.isBefore(ps) && !s.isAfter(pe)) return true;
    }
    return false;
  }

  String _nameForRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${AppStrings.period} ${start.year}-${start.month.toString().padLeft(2, '0')}';
    }
    return '${DateFormat.yMd(AppStrings.languageCode).format(start)} - ${DateFormat.yMd(AppStrings.languageCode).format(end)}';
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
