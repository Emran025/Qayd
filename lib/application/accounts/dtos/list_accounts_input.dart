class ListAccountsInput {
  const ListAccountsInput({
    this.activeOnly = false,
    this.parentAccountId,
  });

  final bool activeOnly;
  final String? parentAccountId;
}
