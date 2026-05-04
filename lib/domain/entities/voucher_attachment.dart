import 'package:flutter/foundation.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Standalone entity for the `attachments` table (many-to-one with vouchers).
///
/// Unlike the light-weight [AttachmentRef] (embedded in the voucher's JSON),
/// this entity represents a first-class row in the [attachments] table with
/// full lifecycle metadata, enabling independent query, sync, and deletion.
@immutable
final class VoucherAttachment {
  const VoucherAttachment({
    required this.id,
    required this.voucherId,
    required this.fileName,
    required this.storagePath,
    required this.encryptedBlobHash,
    required this.mimeType,
    required this.byteSize,
    required this.sourceType,
    required this.createdAt,
    this.thumbnailPath,
    this.attachmentKeyHex,
  });

  /// Unique attachment identifier.
  final AttachmentId id;

  /// Parent voucher this attachment belongs to.
  final VoucherId voucherId;

  /// Human-readable file name (e.g. "invoice_001.jpg").
  final String fileName;

  /// Local filesystem path to the encrypted image file.
  final String storagePath;

  /// SHA-256 hex of the encrypted blob for server-side deduplication.
  final String encryptedBlobHash;

  /// MIME type (e.g. image/jpeg, image/png).
  final String mimeType;

  /// Original (pre-encryption) file size in bytes.
  final int byteSize;

  /// How this attachment was acquired.
  final AttachmentSourceType sourceType;

  /// When this attachment was created.
  final DateTime createdAt;

  /// Optional path to an encrypted thumbnail for fast gallery rendering.
  final String? thumbnailPath;

  /// Per-voucher AES-256 key (hex) used to encrypt this blob.
  ///
  /// Non-null for attachments created with [VoucherKeyService] (v30+).
  /// Null for legacy attachments encrypted with the device-wide DB key.
  /// This key is stored in the SQLCipher DB (never in plaintext on server)
  /// and embedded inside the E2EE sync payload for the counterparty.
  final String? attachmentKeyHex;
}
