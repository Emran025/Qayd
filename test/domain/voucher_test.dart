import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/exceptions/immutable_entity_exception.dart';
import 'package:qayd/domain/exceptions/invalid_amount_exception.dart';
import 'package:qayd/domain/exceptions/invalid_voucher_transition_exception.dart';
import 'package:qayd/domain/exceptions/self_canceling_entry_exception.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

void main() {
  group('Voucher', () {
    final id = VoucherId('v1');
    final cp = AccountId('a1');
    final af = AccountId('a2');
    final sar = PredefinedCurrencies.sar;
    final t = DateTime.utc(2026, 3, 1, 12);
    final created = DateTime.utc(2026, 3, 1, 11);

    test('draft rejects identical counterparty and affected account', () {
      expect(
        () => Voucher.draft(
          id: id,
          type: VoucherType.receipt,
          date: t,
          amount: Money.positiveAmount(100, sar),
          counterpartyId: cp,
          affectedAccountId: cp,
          createdAt: created,
          currency: sar,
        ),
        throwsA(isA<SelfCancelingEntryException>()),
      );
    });

    test('draft rejects zero amount', () {
      expect(
        () => Voucher.draft(
          id: id,
          type: VoucherType.payment,
          date: t,
          amount: Money.nonNegative(0, sar),
          counterpartyId: cp,
          affectedAccountId: af,
          createdAt: created,
          currency: sar,
        ),
        throwsA(isA<InvalidAmountException>()),
      );
    });

    test('confirm only from draft', () {
      final v = Voucher.draft(
        id: id,
        type: VoucherType.receipt,
        date: t,
        amount: Money.positiveAmount(500, sar),
        counterpartyId: cp,
        affectedAccountId: af,
        createdAt: created,
        currency: sar,
      );
      final c = v.confirm(DateTime.utc(2026, 3, 1, 13));
      expect(c.state, VoucherState.confirmed);
      expect(
        () => c.confirm(DateTime.utc(2026, 3, 1, 14)),
        throwsA(isA<InvalidVoucherTransitionException>()),
      );
    });

    test('settle only from confirmed', () {
      final draft = Voucher.draft(
        id: id,
        type: VoucherType.receipt,
        date: t,
        amount: Money.positiveAmount(500, sar),
        counterpartyId: cp,
        affectedAccountId: af,
        createdAt: created,
        currency: sar,
      );
      expect(
        () => draft.settle(DateTime.utc(2026, 3, 2)),
        throwsA(isA<InvalidVoucherTransitionException>()),
      );
      final conf = draft.confirm(DateTime.utc(2026, 3, 1, 13));
      final st = conf.settle(DateTime.utc(2026, 3, 2));
      expect(st.state, VoucherState.settled);
    });

    test('updateDraft rejects when not draft', () {
      final v = Voucher.draft(
        id: id,
        type: VoucherType.receipt,
        date: t,
        amount: Money.positiveAmount(500, sar),
        counterpartyId: cp,
        affectedAccountId: af,
        createdAt: created,
        currency: sar,
      );
      final c = v.confirm(DateTime.utc(2026, 3, 1, 13));
      expect(
        () => c.updateDraft(amount: Money.positiveAmount(600, sar)),
        throwsA(isA<ImmutableEntityException>()),
      );
    });

    test('updateDraft rejects self-canceling pair', () {
      final v = Voucher.draft(
        id: id,
        type: VoucherType.receipt,
        date: t,
        amount: Money.positiveAmount(500, sar),
        counterpartyId: cp,
        affectedAccountId: af,
        createdAt: created,
        currency: sar,
      );
      expect(
        () => v.updateDraft(
          counterpartyId: af,
          affectedAccountId: af,
        ),
        throwsA(isA<SelfCancelingEntryException>()),
      );
    });
  });
}
