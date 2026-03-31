import 'dart:io';
import 'package:qayd/domain/entities/voucher.dart';

abstract interface class ReceiptSharingService {
  /// Opens the system share sheet with a generated PDF of the receipt.
  Future<void> shareAsPdf(Voucher receipt);

  /// Opens the system share sheet with a rendered image of the receipt.
  Future<void> shareAsImage(Voucher receipt);

  /// Opens the system SMS composer with the receipt's text payload.
  Future<void> shareAsSms(Voucher receipt, {String? recipientPhone});

  /// Opens WhatsApp with the receipt's text payload or an attached file.
  Future<void> shareViaWhatsApp(Voucher receipt, {String? recipientPhone});
}
