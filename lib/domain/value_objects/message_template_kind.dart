/// Which business context a [MessageTemplate] applies to.
enum MessageTemplateKind {
  receipt,
  payment,
  accountBalance;

  String get storageCode => switch (this) {
        MessageTemplateKind.receipt => 'receipt',
        MessageTemplateKind.payment => 'payment',
        MessageTemplateKind.accountBalance => 'account_balance',
      };

  static MessageTemplateKind? fromStorage(String? raw) {
    if (raw == null) {
      return null;
    }
    return switch (raw) {
      'receipt' => MessageTemplateKind.receipt,
      'payment' => MessageTemplateKind.payment,
      'account_balance' => MessageTemplateKind.accountBalance,
      _ => null,
    };
  }
}
