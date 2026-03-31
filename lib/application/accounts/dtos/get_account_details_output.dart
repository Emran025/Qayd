class GetAccountDetailsOutput {
  const GetAccountDetailsOutput({
    required this.accountId,
    required this.name,
    required this.natureCode,
    required this.isActive,
    required this.isRoot,
    this.parentId,
    this.parentName,
    required this.balancesMinorUnits,
    required this.createdAtIso,
    this.standardClassificationKind,
    this.customClassificationName,
    this.phoneNumber,
    this.whatsappNumber,
    this.bankAccountInfo,
    this.partyType,
  });

  final String accountId;
  final String name;
  final String natureCode;
  final bool isActive;
  final bool isRoot;
  final String? parentId;
  final String? parentName;

  /// Map of currency code to signed balance in minor units.
  final Map<String, int> balancesMinorUnits;
  final String createdAtIso;
  final String? standardClassificationKind;
  final String? customClassificationName;

  final String? phoneNumber;
  final String? whatsappNumber;
  final String? bankAccountInfo;
  final String? partyType;
}
