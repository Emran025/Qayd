/// Describes what kind of backup the user wants to create.
enum BackupTarget {
  /// Share via system share sheet.
  share,

  /// Save to a user-chosen file path.
  saveToPath,

  /// Save to external device storage (survives uninstall).
  externalStorage,

  /// Trigger the automatic backup immediately.
  autoBackup,
}

/// Configuration for creating a backup.
final class BackupOptions {
  const BackupOptions({
    required this.target,
    this.destinationPath,
  });

  /// Where to put the backup.
  final BackupTarget target;

  /// Required when [target] is [BackupTarget.saveToPath].
  final String? destinationPath;
}
