class CreateAccountOutput {
  const CreateAccountOutput({
    required this.accountId,
    required this.name,
    required this.natureCode,
    required this.isRoot,
    this.parentAccountId,
    required this.createdAtIso,
  });

  final String accountId;
  final String name;
  final String natureCode;
  final bool isRoot;
  final String? parentAccountId;
  final String createdAtIso;
}
