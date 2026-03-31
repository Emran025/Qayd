import 'package:qayd/application/accounts/csv_accounts_import_draft.dart';
import 'package:qayd/application/accounts/create_account_use_case.dart';
import 'package:qayd/application/accounts/dtos/batch_import_accounts_output.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

/// Creates root accounts from parsed CSV rows using [CreateAccountUseCase].
final class BatchImportAccountsFromCsvUseCase {
  BatchImportAccountsFromCsvUseCase(this._createAccount);

  final CreateAccountUseCase _createAccount;

  /// [defaultRootKind] applies when a row has no nature hint (or hint is unrecognized).
  Future<Result<BatchImportAccountsOutput>> call({
    required List<CsvAccountImportDraftRow> rows,
    required StandardAccountClassificationKind defaultRootKind,
  }) async {
    final failures = <BatchImportAccountFailure>[];
    var created = 0;
    for (final row in rows) {
      final kind = _resolveKind(row, defaultRootKind);
      final input = CreateAccountInput(
        name: row.name,
        rootStandardKind: kind,
      );
      final r = await _createAccount(input);
      if (r.isFailure) {
        failures.add(
          BatchImportAccountFailure(
            lineNumber: row.lineNumber,
            messageAr: r.failureOrNull!.messageAr,
          ),
        );
        continue;
      }
      created++;
    }
    return Success(
      BatchImportAccountsOutput(createdCount: created, failures: failures),
    );
  }

  StandardAccountClassificationKind _resolveKind(
    CsvAccountImportDraftRow row,
    StandardAccountClassificationKind defaultKind,
  ) {
    final h = row.natureHint?.trim().toLowerCase();
    if (h == null || h.isEmpty) return defaultKind;
    if (h == 'مدين' ||
        h == 'debit' ||
        h == 'dr' ||
        h == 'd' ||
        h == 'مديني') {
      return StandardAccountClassificationKind.receivables;
    }
    if (h == 'دائن' ||
        h == 'credit' ||
        h == 'cr' ||
        h == 'c' ||
        h == 'دائني') {
      return StandardAccountClassificationKind.payables;
    }
    return defaultKind;
  }
}
