import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher_attachment.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

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
        DatabaseFailure(messageAr: AppStrings.failedToDownloadAttachments),
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
        DatabaseFailure(messageAr: AppStrings.failedToSaveThe),
      );
    }
  }

  @override
  Future<Result<void>> saveAll(List<VoucherAttachment> attachments) async {
    if (attachments.isEmpty) return const Success(null);
    try {
      // Batch insert for performance
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
    } catch (_) {
      // Batch failed — fall back to sequential inserts so partial success
      // is still captured (e.g. one attachment already exists vs. all failing)
      var anyFailed = false;
      for (final a in attachments) {
        try {
          await _db.insert(
            _table,
            _toRow(a),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {
          anyFailed = true;
        }
      }
      if (anyFailed) {
        return FailureResult(
          DatabaseFailure(messageAr: AppStrings.failedToSaveSome),
        );
      }
      return const Success(null);
    }
  }

  @override
  Future<Result<void>> delete(AttachmentId id) async {
    try {
      await _db.delete(_table, where: 'id = ?', whereArgs: [id.value]);
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.failedToDeleteThe),
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
        DatabaseFailure(messageAr: AppStrings.failedToDeleteBond),
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
        // §5.E: per-attachment AES key (null for legacy blobs).
        'attachment_key_hex': a.attachmentKeyHex,
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
        // §5.E: per-attachment key — null for legacy blobs (pre-v30).
        attachmentKeyHex: row['attachment_key_hex'] as String?,
      );

  // ── Post-restore path healing ────────────────────────────────────────────────

  /// Heals stale [storage_path] values after a backup restore.
  ///
  /// On a new device (or after reinstall) the absolute paths stored in the DB
  /// point to the old device's filesystem. This method builds a filename→path
  /// index from all files found inside [newImagesDir] (recursive) and updates
  /// every row whose `storage_path` no longer exists on disk.
  ///
  /// Safe to call multiple times (idempotent — skips paths that already exist).
  Future<void> healStoragePathsAfterRestore(Directory newImagesDir) async {
    if (!newImagesDir.existsSync()) return;

    // Build filename → absolute-path index.
    final index = <String, String>{};
    for (final entity
        in newImagesDir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        index[p.basename(entity.path)] = entity.path;
      }
    }

    final rows = await _db.query(
      _table,
      columns: ['id', 'storage_path'],
    );

    final batch = _db.batch();
    int healed = 0;

    for (final row in rows) {
      final id = row['id'] as String;
      final storedPath = row['storage_path'] as String;
      // Skip: already correct, or empty (inbound attachment not yet downloaded).
      if (storedPath.isEmpty || File(storedPath).existsSync()) continue;

      final newPath = index[p.basename(storedPath)];
      if (newPath != null) {
        batch.update(
          _table,
          {'storage_path': newPath},
          where: 'id = ?',
          whereArgs: [id],
        );
        healed++;
      }
    }

    if (healed > 0) await batch.commit(noResult: true);
  }
}
