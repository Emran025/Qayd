class ListAccountsInput {
  const ListAccountsInput({
    this.activeOnly = false,
    this.excludeArchived = true,
    this.parentAccountId,
  });

  final bool activeOnly;
  final bool excludeArchived;
  final String? parentAccountId;
}
