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
    this.involvedRootAccountId,
    this.involvedCounterRootAccountId,
    this.isInternalOnly,
  });

  final VoucherType? type;
  final VoucherState? state;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? counterpartyAccountId;
  final String? affectedAccountId;
  final String? costCenterId;
  final String? involvedRootAccountId;
  final String? involvedCounterRootAccountId;
  final bool? isInternalOnly;

  static const AdvancedFilterInput empty = AdvancedFilterInput();

  bool get hasAny =>
      type != null ||
      state != null ||
      fromDate != null ||
      toDate != null ||
      (counterpartyAccountId != null && counterpartyAccountId!.isNotEmpty) ||
      (affectedAccountId != null && affectedAccountId!.isNotEmpty) ||
      (costCenterId != null && costCenterId!.isNotEmpty) ||
      (involvedRootAccountId != null && involvedRootAccountId!.isNotEmpty) ||
      isInternalOnly == true;

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

  AdvancedFilterInput copyWith({
    VoucherType? type,
    VoucherState? state,
    DateTime? fromDate,
    DateTime? toDate,
    String? counterpartyAccountId,
    String? affectedAccountId,
    String? costCenterId,
    String? involvedRootAccountId,
    String? involvedCounterRootAccountId,
    bool? isInternalOnly,
  }) {
    return AdvancedFilterInput(
      type: type ?? this.type,
      state: state ?? this.state,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      counterpartyAccountId:
          counterpartyAccountId ?? this.counterpartyAccountId,
      affectedAccountId: affectedAccountId ?? this.affectedAccountId,
      costCenterId: costCenterId ?? this.costCenterId,
      involvedRootAccountId:
          involvedRootAccountId ?? this.involvedRootAccountId,
      involvedCounterRootAccountId:
          involvedCounterRootAccountId ?? this.involvedCounterRootAccountId,
      isInternalOnly: isInternalOnly ?? this.isInternalOnly,
    );
  }
}
