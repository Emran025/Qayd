import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher_attachment.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// SQLite-backed implementation of [AttachmentRepository].
final class SqliteAttachmentRepository implements AttachmentRepository {
  SqliteAttachmentRepository(this._db);

  final Database _db;

  static const _table = 'attachments';

  @override
  Future<Result<List<VoucherAttachment>>> getByVoucherId(
    VoucherId voucherId,
  ) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'voucher_id = ?',
        whereArgs: [voucherId.value],
        orderBy: 'created_at ASC',
      );
      final attachments = rows.map(_fromRow).toList();
      return Success(attachments);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في تحميل المرفقات.'),
      );
    }
  }

  @override
  Future<Result<void>> save(VoucherAttachment attachment) async {
    try {
      await _db.insert(
        _table,
        _toRow(attachment),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في حفظ المرفق.'),
      );
    }
  }

  @override
  Future<Result<void>> saveAll(List<VoucherAttachment> attachments) async {
    try {
      final batch = _db.batch();
      for (final a in attachments) {
        batch.insert(
          _table,
          _toRow(a),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في حفظ المرفقات.'),
      );
    }
  }

  @override
  Future<Result<void>> delete(AttachmentId id) async {
    try {
      await _db.delete(_table, where: 'id = ?', whereArgs: [id.value]);
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في حذف المرفق.'),
      );
    }
  }

  @override
  Future<Result<void>> deleteAllForVoucher(VoucherId voucherId) async {
    try {
      await _db.delete(
        _table,
        where: 'voucher_id = ?',
        whereArgs: [voucherId.value],
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في حذف مرفقات السند.'),
      );
    }
  }

  // ── Mapping helpers ─────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(VoucherAttachment a) => {
        'id': a.id.value,
        'voucher_id': a.voucherId.value,
        'file_name': a.fileName,
        'storage_path': a.storagePath,
        'encrypted_blob_hash': a.encryptedBlobHash,
        'mime_type': a.mimeType,
        'byte_size': a.byteSize,
        'source_type': a.sourceType.name,
        'thumbnail_path': a.thumbnailPath,
        'created_at': a.createdAt.toIso8601String(),
      };

  VoucherAttachment _fromRow(Map<String, dynamic> row) => VoucherAttachment(
        id: AttachmentId(row['id'] as String),
        voucherId: VoucherId(row['voucher_id'] as String),
        fileName: row['file_name'] as String,
        storagePath: row['storage_path'] as String,
        encryptedBlobHash: row['encrypted_blob_hash'] as String,
        mimeType: row['mime_type'] as String,
        byteSize: row['byte_size'] as int,
        sourceType:
            AttachmentSourceType.fromString(row['source_type'] as String),
        thumbnailPath: row['thumbnail_path'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
