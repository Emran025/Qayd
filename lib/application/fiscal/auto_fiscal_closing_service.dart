import 'dart:async';

import 'package:qayd/application/fiscal/close_fiscal_period_use_case.dart';
import 'package:qayd/application/fiscal/create_fiscal_period_use_case.dart';
import 'package:qayd/domain/entities/fiscal_period.dart';
import 'package:qayd/domain/repositories/fiscal_period_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qayd/core/result/result.dart';

/// Runtime timer that enforces automatic close/open fiscal cycling.
final class AutoFiscalClosingService {
  AutoFiscalClosingService({
    required SharedPreferences prefs,
    required FiscalPeriodRepository fiscalRepository,
    required CreateFiscalPeriodUseCase createFiscalPeriodUseCase,
    required CloseFiscalPeriodUseCase closeFiscalPeriodUseCase,
  })  : _prefs = prefs,
        _fiscalRepository = fiscalRepository,
        _createFiscalPeriodUseCase = createFiscalPeriodUseCase,
        _closeFiscalPeriodUseCase = closeFiscalPeriodUseCase;

  final SharedPreferences _prefs;
  final FiscalPeriodRepository _fiscalRepository;
  final CreateFiscalPeriodUseCase _createFiscalPeriodUseCase;
  final CloseFiscalPeriodUseCase _closeFiscalPeriodUseCase;

  Timer? _timer;
  bool _busy = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final policy = _prefs.getString('fiscal_closing_policy') ?? 'manual';
      if (policy != 'auto_periodic') return;

      final frequency = _prefs.getString('fiscal_auto_frequency') ?? 'monthly';
      DateTime anchor = _readAnchor() ?? DateTime.now().toUtc();
      anchor = DateTime(anchor.year, anchor.month, anchor.day);

      final allR = await _fiscalRepository.listAllOrdered();
      if (allR.isFailure) return;
      final periods = allR.valueOrNull!;
      final open =
          periods.where((p) => p.status == FiscalPeriodStatus.open).toList();

      if (open.isEmpty) {
        final endExclusive = _nextBoundary(anchor, frequency);
        await _createPeriod(anchor, endExclusive);
        return;
      }

      final openPeriod = open.first;
      final endExclusive = _nextBoundary(anchor, frequency);
      final now = DateTime.now().toUtc();
      if (now.isBefore(endExclusive)) return;

      final closeR = await _closeFiscalPeriodUseCase.call(
        openPeriod.id,
        byAutomation: true,
      );
      if (closeR.isFailure) return;

      final newAnchor = DateTime(now.year, now.month, now.day);
      await _prefs.setString(
          'fiscal_auto_start_date', newAnchor.toIso8601String());
      final nextEndExclusive = _nextBoundary(newAnchor, frequency);
      await _createPeriod(newAnchor, nextEndExclusive);
    } finally {
      _busy = false;
    }
  }

  Future<void> _createPeriod(DateTime start, DateTime endExclusive) async {
    final endInclusive = endExclusive.subtract(const Duration(days: 1));
    final name = _periodName(start, endInclusive);
    await _createFiscalPeriodUseCase.call(
      name: name,
      startDate: start,
      endDate: endInclusive,
    );
  }

  DateTime? _readAnchor() {
    final raw = _prefs.getString('fiscal_auto_start_date');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  DateTime _nextBoundary(DateTime start, String frequency) {
    return switch (frequency) {
      'weekly' => start.add(const Duration(days: 7)),
      'annually' => DateTime(start.year + 1, start.month, start.day),
      _ => DateTime(start.year, start.month + 1, start.day),
    };
  }

  String _periodName(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return 'Period ${start.year}-${start.month.toString().padLeft(2, '0')}';
    }
    return 'Period ${start.toIso8601String().substring(0, 10)} to ${end.toIso8601String().substring(0, 10)}';
  }
}
