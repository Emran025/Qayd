import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

class UpdateAccountInput {
  const UpdateAccountInput({
    required this.accountId,
    required this.newName,
    this.parentAccountId,
    this.rootStandardKind,
    this.customClassificationName,
    this.customClassificationNature,
    this.phoneNumber,
    this.whatsappNumber,
    this.bankAccountInfo,
    this.partyType,
    this.defaultCostCenters,
  });

  final String accountId;
  final String newName;

  /// Structural updates
  final String? parentAccountId;
  final StandardAccountClassificationKind? rootStandardKind;
  final String? customClassificationName;
  final AccountNature? customClassificationNature;

  /// If non-null, party details will be updated (upserted) for this account.
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? bankAccountInfo;
  final String? partyType;

  /// If non-null, default cost centers will be replaced with this list.
  final List<CostCenterTagInput>? defaultCostCenters;
}
