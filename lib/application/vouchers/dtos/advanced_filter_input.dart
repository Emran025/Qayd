import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// UI / application filter for voucher lists (maps to [VoucherQueryFilter]).
class AdvancedFilterInput {
  const AdvancedFilterInput({
    this.type,
    this.state,
    this.fromDate,
    this.toDate,
    this.counterpartyAccountId,
    this.affectedAccountId,
  });

  final VoucherType? type;
  final VoucherState? state;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? counterpartyAccountId;
  final String? affectedAccountId;

  static const AdvancedFilterInput empty = AdvancedFilterInput();

  bool get hasAny =>
      type != null ||
      state != null ||
      fromDate != null ||
      toDate != null ||
      (counterpartyAccountId != null && counterpartyAccountId!.isNotEmpty) ||
      (affectedAccountId != null && affectedAccountId!.isNotEmpty);

  AdvancedFilterInput clearType() => AdvancedFilterInput(
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
      );

  AdvancedFilterInput clearState() => AdvancedFilterInput(
        type: type,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
      );

  AdvancedFilterInput clearDateRange() => AdvancedFilterInput(
        type: type,
        state: state,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
      );

  AdvancedFilterInput clearCounterparty() => AdvancedFilterInput(
        type: type,
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        affectedAccountId: affectedAccountId,
      );

  AdvancedFilterInput clearAffected() => AdvancedFilterInput(
        type: type,
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
      );
}
