import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';

/// Reference to an attachment stored by the app (path is non-empty).
///
/// Carries E2EE metadata: [encryptedBlobHash] enables content-blind server
/// deduplication, [thumbnailPath] points to a locally-encrypted thumbnail
/// for fast gallery rendering.
final class AttachmentRef {
  AttachmentRef({
    required this.id,
    required this.storagePath,
    this.mimeType,
    this.byteSize,
    this.encryptedBlobHash,
    this.thumbnailPath,
    this.sourceType = AttachmentSourceType.gallery,
  }) {
    if (storagePath.trim().isEmpty) {
      throw ArgumentError.value(
        storagePath,
        'storagePath',
        'Attachment path must be non-empty',
      );
    }
  }

  /// Unique attachment identifier.
  final AttachmentId id;

  /// Local filesystem path to the encrypted blob.
  final String storagePath;

  /// MIME type (e.g. image/jpeg, image/png).
  final String? mimeType;

  /// Original (pre-encryption) file size in bytes.
  final int? byteSize;

  /// SHA-256 hex of the encrypted blob; used for server-side deduplication.
  final String? encryptedBlobHash;

  /// Local path to the encrypted thumbnail for gallery previews.
  final String? thumbnailPath;

  /// How this attachment was acquired (camera, gallery, document import).
  final AttachmentSourceType sourceType;
}
