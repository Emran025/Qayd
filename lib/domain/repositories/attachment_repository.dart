import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher_attachment.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Repository contract for voucher attachment persistence.
abstract interface class AttachmentRepository {
  /// Returns all attachments belonging to a voucher.
  Future<Result<List<VoucherAttachment>>> getByVoucherId(VoucherId voucherId);

  /// Persists a single attachment.
  Future<Result<void>> save(VoucherAttachment attachment);

  /// Persists multiple attachments in a single transaction.
  Future<Result<void>> saveAll(List<VoucherAttachment> attachments);

  /// Deletes a single attachment by ID.
  Future<Result<void>> delete(AttachmentId id);

  /// Deletes all attachments for a voucher (cascade on voucher deletion).
  Future<Result<void>> deleteAllForVoucher(VoucherId voucherId);
}
