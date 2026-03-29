/// Reference to an attachment stored by the app (path is non-empty).
final class AttachmentRef {
  AttachmentRef({required this.storagePath, this.mimeType, this.byteSize}) {
    if (storagePath.trim().isEmpty) {
      throw ArgumentError.value(
        storagePath,
        'storagePath',
        'Attachment path must be non-empty',
      );
    }
  }

  final String storagePath;
  final String? mimeType;
  final int? byteSize;
}
