import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/pos/build_pos_opening_balance_posting_use_case.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/money.dart';

CurrencyCode _currency() => CurrencyCode(
      code: 'SAR',
      nameAr: 'ريال سعودي',
      symbol: 'ر.س',
    );

BuildPosOpeningBalancePostingInput _input({
  String sourceId = 'opening-source-1',
  String inventoryAccountId = 'inventory-account',
  String clearingAccountId = 'clearing-account',
  int amountMinorUnits = 1250,
}) {
  return BuildPosOpeningBalancePostingInput(
    sourceId: sourceId,
    voucherId: 'voucher-1',
    transactionId: 'transaction-1',
    debitEntryId: 'debit-1',
    creditEntryId: 'credit-1',
    inventoryAccountId: inventoryAccountId,
    clearingAccountId: clearingAccountId,
    amountMinorUnits: amountMinorUnits,
    currency: _currency(),
    date: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1, 10),
  );
}

void main() {
  final useCase = BuildPosOpeningBalancePostingUseCase();

  test('builds a confirmed balanced opening-stock posting', () async {
    final result = await useCase(_input());

    expect(result.isSuccess, isTrue);
    final posting = result.valueOrNull!;
    expect(posting.sourceId, 'opening-source-1');
    expect(posting.voucher.state.isConfirmed, isTrue);
    expect(posting.voucher.amount, Money.fromMinorUnits(1250, _currency()));
    expect(posting.entries, hasLength(2));
    expect(posting.entries[0].accountId.value, 'inventory-account');
    expect(posting.entries[0].side, EntrySide.debit);
    expect(posting.entries[1].accountId.value, 'clearing-account');
    expect(posting.entries[1].side, EntrySide.credit);
    expect(posting.entries[0].transactionId.value, 'transaction-1');
    expect(posting.entries[1].transactionId.value, 'transaction-1');
  });

  test('rejects an empty source reference', () async {
    final result = await useCase(_input(sourceId: '  '));

    expect(result.isFailure, isTrue);
  });

  test('rejects identical posting accounts', () async {
    final result = await useCase(
      _input(
        inventoryAccountId: 'same-account',
        clearingAccountId: 'same-account',
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('rejects a zero opening value before entry generation', () async {
    final result = await useCase(_input(amountMinorUnits: 0));

    expect(result.isFailure, isTrue);
  });
}
