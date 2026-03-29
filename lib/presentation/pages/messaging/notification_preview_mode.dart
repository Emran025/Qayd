sealed class NotificationPreviewMode {
  const NotificationPreviewMode();
}

final class NotificationPreviewVoucher extends NotificationPreviewMode {
  const NotificationPreviewVoucher(this.voucherId);

  final String voucherId;
}

final class NotificationPreviewAccount extends NotificationPreviewMode {
  const NotificationPreviewAccount(this.accountId);

  final String accountId;
}
