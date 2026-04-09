/// Normal balance direction for an account; governs how debits and credits affect balance.
enum AccountNature {
  debit,
  credit;

  bool get isDebit => this == AccountNature.debit;
  bool get isCredit => this == AccountNature.credit;
}
