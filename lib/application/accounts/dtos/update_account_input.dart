class UpdateAccountInput {
  const UpdateAccountInput({
    required this.accountId,
    required this.newName,
  });

  final String accountId;
  final String newName;
}
