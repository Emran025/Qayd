import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qayd/application/reports/dtos/generate_trial_balance_input.dart';
import 'package:qayd/application/reports/generate_trial_balance_use_case.dart';
import 'package:qayd/core/result/result.dart';

import 'package:qayd/data/excel/reports/excel_report_generator.dart';
import 'package:qayd/data/pdf/cairo_pdf_fonts.dart';
import 'package:qayd/data/pdf/reports/trial_balance_pdf_generator.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_state.dart';
import 'package:share_plus/share_plus.dart';

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

    try {
      final ttf = await CairoPdfFonts.font;

      const generator = TrialBalancePdfGenerator();
      final bytes = await generator.generate(currentState.output, ttf);

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/trial_balance_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ميزان المراجعة — نظام قيد',
      );
    } catch (_) {
      // TODO: surface export errors to user
    }
  }

  Future<void> exportExcel() async {
    final currentState = state;
    if (currentState is! TrialBalanceReady) return;

    try {
      const generator = ExcelReportGenerator();
      final bytes = generator.generateTrialBalance(currentState.output);

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/trial_balance_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ميزان المراجعة — نظام قيد',
      );
    } catch (_) {
      // TODO: surface export errors to user
    }
  }
}
