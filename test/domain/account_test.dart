import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/exceptions/account_deletion_exception.dart';
import 'package:qayd/domain/exceptions/invalid_state_transition_exception.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

void main() {
  group('Account', () {
    final id = AccountId('acc-1');
    final sar = PredefinedCurrencies.sar;
    final now = DateTime.utc(2026, 1, 1);

    test('createRoot trims name and sets classification nature', () {
      final a = Account.createRoot(
        id: id,
        name: '  نقد  ',
        classification: AccountClassification.liquidAssets,
        createdAt: now,
      );
      expect(a.name, 'نقد');
      expect(a.nature, AccountNature.debit);
      expect(a.isRoot, true);
      expect(a.classification.standardKind,
          StandardAccountClassificationKind.liquidAssets);
    });

    test('createRoot rejects empty name', () {
      expect(
        () => Account.createRoot(
          id: id,
          name: '   ',
          classification: AccountClassification.liquidAssets,
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('createChild inherits parent classification and nature', () {
      final parent = Account.createRoot(
        id: AccountId('p'),
        name: 'أب',
        classification: AccountClassification.payables,
        createdAt: now,
      );
      final child = Account.createChild(
        id: AccountId('c'),
        name: 'ابن',
        parent: parent,
        createdAt: now,
      );
      expect(child.parentId, parent.id);
      expect(child.nature, parent.nature);
      expect(child.classification, parent.classification);
    });

    test('deactivate requires zero balance', () {
      final a = Account.createRoot(
        id: id,
        name: 'حساب',
        classification: AccountClassification.settlements,
        createdAt: now,
      );
      expect(
        () => a.deactivate(balance: Money.positiveAmount(1, sar)),
        throwsA(isA<AccountDeletionException>()),
      );
      final d = a.deactivate(balance: Money.zero(sar));
      expect(d.isActive, false);
    });

    test('relocateUnder rejects parent with different classification', () {
      final debitRoot = Account.createRoot(
        id: AccountId('d'),
        name: 'دائن',
        classification: AccountClassification.liquidAssets,
        createdAt: now,
      );
      final creditRoot = Account.createRoot(
        id: AccountId('cr'),
        name: 'مدين',
        classification: AccountClassification.payables,
        createdAt: now,
      );
      final child = Account.createChild(
        id: AccountId('ch'),
        name: 'فرع',
        parent: debitRoot,
        createdAt: now,
      );
      expect(
        () => child.relocateUnder(creditRoot),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('assertCanDelete rejects non-zero balance and children', () {
      final a = Account.createRoot(
        id: id,
        name: 'x',
        classification: AccountClassification.liquidAssets,
        createdAt: now,
      );
      expect(
        () => a.assertCanDelete(
          balance: Money.positiveAmount(1, sar),
          hasChildAccounts: false,
        ),
        throwsA(isA<AccountDeletionException>()),
      );
      expect(
        () => a.assertCanDelete(
          balance: Money.zero(sar),
          hasChildAccounts: true,
        ),
        throwsA(isA<AccountDeletionException>()),
      );
    });
  });
}
