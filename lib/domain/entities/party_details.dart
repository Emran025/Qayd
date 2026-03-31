import 'package:qayd/domain/value_objects/account_id.dart';

class PartyDetails {
  const PartyDetails({
    required this.accountId,
    this.phoneNumber,
    this.whatsappNumber,
    this.bankAccountInfo,
    this.partyType,
  });

  final AccountId accountId;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? bankAccountInfo;
  final String? partyType;
}
