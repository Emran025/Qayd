import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/balance_sheet_output.dart';
import 'package:qayd/application/reports/generate_balance_sheet_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/excel/reports/excel_report_generator.dart';
import 'package:qayd/data/pdf/reports/balance_sheet_pdf_generator.dart';
import 'package:qayd/presentation/utils/share_export_bytes.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ── STATE ────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

sealed class BalanceSheetState {
  const BalanceSheetState();
}

final class BalanceSheetInitial extends BalanceSheetState {
  const BalanceSheetInitial();
}

final class BalanceSheetLoading extends BalanceSheetState {
  const BalanceSheetLoading();
}

final class BalanceSheetReady extends BalanceSheetState {
  const BalanceSheetReady(this.output, {this.isExporting = false});
  final BalanceSheetOutput output;
  final bool isExporting;
}

final class BalanceSheetFailure extends BalanceSheetState {
  const BalanceSheetFailure(this.message);
  final String message;
}

// ═══════════════════════════════════════════════════════════════════════════
// ── CUBIT ────────────────────────────────────════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

class BalanceSheetCubit extends Cubit<BalanceSheetState> {
  BalanceSheetCubit(this._useCase) : super(const BalanceSheetInitial());

  final GenerateBalanceSheetUseCase _useCase;

  Future<void> load() async {
    emit(const BalanceSheetLoading());
    final result = await _useCase(DateTime.now());
    result.fold(
      (f) => emit(BalanceSheetFailure(f.messageAr)),
      (output) => emit(BalanceSheetReady(output)),
    );
  }

  Future<void> exportPdf() async {
    final currentState = state;
    if (currentState is! BalanceSheetReady) return;

    emit(BalanceSheetReady(currentState.output, isExporting: true));
    try {
      const generator = BalanceSheetPdfGenerator();
      final bytes = await generator.generate(currentState.output);

      await sharePdfBytes(
        bytes,
        'balance_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf',
        text: 'الميزانية العمومية — نظام قيد',
      );
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('BalanceSheet PDF Error: $e\n$stackTrace');
      emit(BalanceSheetFailure('تعذر تصدير الميزانية العمومية كـ PDF: $e'));
      return;
    }
    emit(BalanceSheetReady(currentState.output));
  }

  Future<void> exportExcel() async {
    final currentState = state;
    if (currentState is! BalanceSheetReady) return;

    emit(BalanceSheetReady(currentState.output, isExporting: true));
    try {
      const generator = ExcelReportGenerator();
      final bytes = generator.generateBalanceSheet(currentState.output);

      await shareExportBytes(
        bytes,
        'balance_sheet_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      emit(BalanceSheetFailure('تعذر تصدير الميزانية العمومية كـ Excel: $e'));
      return;
    }
    emit(BalanceSheetReady(currentState.output));
  }
}
