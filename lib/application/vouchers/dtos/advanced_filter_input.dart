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
    this.costCenterId,
  });

  final VoucherType? type;
  final VoucherState? state;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? counterpartyAccountId;
  final String? affectedAccountId;
  final String? costCenterId;

  static const AdvancedFilterInput empty = AdvancedFilterInput();

  bool get hasAny =>
      type != null ||
      state != null ||
      fromDate != null ||
      toDate != null ||
      (counterpartyAccountId != null && counterpartyAccountId!.isNotEmpty) ||
      (affectedAccountId != null && affectedAccountId!.isNotEmpty) ||
      (costCenterId != null && costCenterId!.isNotEmpty);

  AdvancedFilterInput clearType() => AdvancedFilterInput(
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
        costCenterId: costCenterId,
      );

  AdvancedFilterInput clearState() => AdvancedFilterInput(
        type: type,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
        costCenterId: costCenterId,
      );

  AdvancedFilterInput clearDateRange() => AdvancedFilterInput(
        type: type,
        state: state,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
        costCenterId: costCenterId,
      );

  AdvancedFilterInput clearCounterparty() => AdvancedFilterInput(
        type: type,
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        affectedAccountId: affectedAccountId,
        costCenterId: costCenterId,
      );

  AdvancedFilterInput clearAffected() => AdvancedFilterInput(
        type: type,
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
        costCenterId: costCenterId,
      );

  AdvancedFilterInput clearCostCenter() => AdvancedFilterInput(
        type: type,
        state: state,
        fromDate: fromDate,
        toDate: toDate,
        counterpartyAccountId: counterpartyAccountId,
        affectedAccountId: affectedAccountId,
      );
}
