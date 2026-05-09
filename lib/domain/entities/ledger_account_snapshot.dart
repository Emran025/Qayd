import 'package:qayd/domain/value_objects/account_id.dart';

/// One account/currency balance line sealed into a closed fiscal period.
final class LedgerAccountSnapshot {
  const LedgerAccountSnapshot({
    required this.id,
    required this.periodId,
    required this.accountId,
    required this.balanceMinorUnits,
    required this.currencyCode,
    required this.rowHash,
  });

  final String id;
  final String periodId;
  final AccountId accountId;
  final int balanceMinorUnits;
  final String currencyCode;
  final String rowHash;
}
