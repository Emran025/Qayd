import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qayd/application/reports/dtos/balance_sheet_output.dart';
import 'package:qayd/application/reports/generate_balance_sheet_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/excel/reports/excel_report_generator.dart';
import 'package:qayd/data/pdf/cairo_pdf_fonts.dart';
import 'package:qayd/data/pdf/reports/balance_sheet_pdf_generator.dart';
import 'package:share_plus/share_plus.dart';

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
      final ttf = await CairoPdfFonts.font;

      const generator = BalanceSheetPdfGenerator();
      final bytes = await generator.generate(currentState.output, ttf);

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/balance_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'الميزانية العمومية — نظام قيد',
      );
    } catch (e) {
      emit(BalanceSheetFailure('تعذر تصدير الملف: $e'));
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

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/balance_sheet_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'الميزانية العمومية — نظام قيد',
      );
    } catch (e) {
      emit(BalanceSheetFailure('تعذر تصدير الملف: $e'));
      return;
    }
    emit(BalanceSheetReady(currentState.output));
  }
}
