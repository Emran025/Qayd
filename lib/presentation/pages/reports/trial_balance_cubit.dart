import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/generate_trial_balance_input.dart';
import 'package:qayd/application/reports/generate_trial_balance_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

import 'package:qayd/data/excel/reports/excel_report_generator.dart';
import 'package:qayd/data/pdf/reports/trial_balance_pdf_generator.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_state.dart';
import 'package:qayd/presentation/utils/share_export_bytes.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';

class TrialBalanceCubit extends Cubit<TrialBalanceState> {
  TrialBalanceCubit(this._generate) : super(const TrialBalanceInitial());

  final GenerateTrialBalanceUseCase _generate;

  Future<void> load() async {
    emit(const TrialBalanceLoading());
    final result = await _generate(const GenerateTrialBalanceInput());
    result.fold(
      (f) => emit(TrialBalanceFailure(f)),
      (output) => emit(TrialBalanceReady(output)),
    );
  }

  Future<void> exportPdf() async {
    final currentState = state;
    if (currentState is! TrialBalanceReady) return;

    emit(TrialBalanceReady(currentState.output, isExporting: true));
    try {
      const generator = TrialBalancePdfGenerator();
      final bytes = await generator.generate(currentState.output);

      await sharePdfBytes(
        bytes,
        'trial_balance_${DateTime.now().millisecondsSinceEpoch}.pdf',
        text: 'ميزان المراجعة — نظام قيد',
      );
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('TrialBalance PDF Error: $e\n$stackTrace');
      emit(TrialBalanceFailure(
        FileSystemFailure(messageAr: 'تعذر تصدير ميزان المراجعة كـ PDF: $e'),
      ));
      return;
    }
    emit(TrialBalanceReady(currentState.output));
  }

  Future<void> exportExcel() async {
    final currentState = state;
    if (currentState is! TrialBalanceReady) return;

    emit(TrialBalanceReady(currentState.output, isExporting: true));
    try {
      const generator = ExcelReportGenerator();
      final bytes = generator.generateTrialBalance(currentState.output);

      await shareExportBytes(
        bytes,
        'trial_balance_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      emit(TrialBalanceFailure(
        FileSystemFailure(messageAr: 'تعذر تصدير ميزان المراجعة كـ Excel: $e'),
      ));
      return;
    }
    emit(TrialBalanceReady(currentState.output));
  }
}
