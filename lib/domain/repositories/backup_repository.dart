import 'package:qayd/core/result/result.dart';

/// Abstraction for cloud-based backup storage (e.g. Google Drive).
///
/// Currently unused because Google Drive integration is suspended.
/// When enabled, [GoogleDriveBackupRepository] will implement this.
abstract interface class BackupRepository {
  /// Uploads the database file to cloud storage.
  Future<Result<void>> uploadDatabase(String localPath);

  /// Downloads the most recent database backup from cloud storage.
  Future<Result<String>> downloadLatestDatabase();

  /// Uploads the identity key file to cloud storage.
  Future<Result<void>> uploadIdentityFile(String localPath);

  /// Downloads the identity key file from cloud storage.
  Future<Result<String>> downloadIdentityFile();

  /// Whether the user is signed in to the cloud service.
  Future<bool> isSignedIn();

  /// Signs the user in to the cloud service.
  Future<Result<void>> signIn();

  /// Signs the user out of the cloud service.
  Future<Result<void>> signOut();

  /// Returns the date of the most recent cloud backup, or null.
  Future<DateTime?> lastBackupDate();
}
