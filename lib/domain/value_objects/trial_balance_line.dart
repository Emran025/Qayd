import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

/// One row in a trial balance: amounts in minor units in debit and/or credit columns.
final class TrialBalanceLine {
  const TrialBalanceLine({
    required this.accountId,
    required this.currency,
    required this.debitMinorUnits,
    required this.creditMinorUnits,
  }) : assert(debitMinorUnits >= 0 && creditMinorUnits >= 0);

  final AccountId accountId;
  final CurrencyCode currency;
  final int debitMinorUnits;
  final int creditMinorUnits;

  /// Maps signed minor units (debit-nature: debits − credits; credit-nature: credits − debits)
  /// into non-negative debit and credit display columns.
  factory TrialBalanceLine.fromSignedBalance({
    required AccountId accountId,
    required AccountNature accountNature,
    required CurrencyCode currency,
    required int signedMinorUnits,
  }) {
    if (signedMinorUnits == 0) {
      return TrialBalanceLine(
        accountId: accountId,
        currency: currency,
        debitMinorUnits: 0,
        creditMinorUnits: 0,
      );
    }
    if (accountNature == AccountNature.debit) {
      if (signedMinorUnits > 0) {
        return TrialBalanceLine(
          accountId: accountId,
          currency: currency,
          debitMinorUnits: signedMinorUnits,
          creditMinorUnits: 0,
        );
      }
      return TrialBalanceLine(
        accountId: accountId,
        currency: currency,
        debitMinorUnits: 0,
        creditMinorUnits: -signedMinorUnits,
      );
    }
    if (signedMinorUnits > 0) {
      return TrialBalanceLine(
        accountId: accountId,
        currency: currency,
        debitMinorUnits: 0,
        creditMinorUnits: signedMinorUnits,
      );
    }
    return TrialBalanceLine(
      accountId: accountId,
      currency: currency,
      debitMinorUnits: -signedMinorUnits,
      creditMinorUnits: 0,
    );
  }
}
