/// How an attachment was captured or sourced.
enum AttachmentSourceType {
  gallery,
  camera,
  document;

  static AttachmentSourceType fromString(String val) {
    return AttachmentSourceType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AttachmentSourceType.gallery,
    );
  }
}
