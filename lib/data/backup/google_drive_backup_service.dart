import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/database/database_provider.dart';

/// Google Drive backup service — mirrors WhatsApp's Drive backup model.
///
/// Uses [Dio] to call the Drive REST API v3 directly (no googleapis package).
/// Uploads the encrypted database + identity file to Google Drive's **appDataFolder**
/// (hidden from the user, only accessible by this app). Supports:
///
/// - Sign-in / sign-out with Google account.
/// - Manual and automatic daily uploads.
/// - Restore from Drive (same device or new device after account recovery).
/// - Settings persisted in [FlutterSecureStorage].
///
/// Drive folder structure:
/// ```
/// appDataFolder/
///   qayd_backup_latest.db        ← most recent database snapshot
///   qayd_identity.dat            ← encrypted identity (mnemonic + keys)
///   qayd_db_key.dat              ← DB encryption key
/// ```
final class GoogleDriveBackupService {
  GoogleDriveBackupService({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio();

  final FlutterSecureStorage _storage;
  final Dio _dio;

  static const _kEnabled = 'qayd_drive_backup_enabled_v1';
  static const _kLastDate = 'qayd_drive_backup_last_date_v1';
  static const _kAccountEmail = 'qayd_drive_backup_account_v1';

  static const _driveApiBase = 'https://www.googleapis.com';
  static const _driveFilesUrl = '$_driveApiBase/drive/v3/files';
  static const _driveUploadUrl = '$_driveApiBase/upload/drive/v3/files';

  // File names on Drive.
  static const _driveDbFileName = 'qayd_backup_latest.db';
  static const _driveIdentityFileName = 'qayd_identity.dat';
  static const _driveDbKeyFileName = 'qayd_db_key.dat';

  // Local identity file name (must match IdentityFileStorage._fileName).
  static const _localIdentityFileName = 'qayd_identity.dat';

  // Google Sign-In instance — request drive.appdata scope.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  // ── Sign-in state ─────────────────────────────────────────────────────────

  /// Whether the user is currently signed in to Google.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// The signed-in Google account email, or null.
  String? get accountEmail => _googleSignIn.currentUser?.email;

  /// Attempts to sign in silently first, then interactively if needed.
  Future<Result<String>> signIn() async {
    try {
      var account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) {
        return const FailureResult(
          AuthFailure(messageAr: 'تم إلغاء تسجيل الدخول.'),
        );
      }
      await _storage.write(key: _kAccountEmail, value: account.email);
      return Success(account.email);
    } catch (e) {
      return FailureResult(
        AuthFailure(messageAr: 'فشل تسجيل الدخول إلى Google: $e'),
      );
    }
  }

  /// Signs out from Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _kAccountEmail);
    await _storage.delete(key: _kEnabled);
    await _storage.delete(key: _kLastDate);
  }

  /// Returns the previously stored account email (for display when offline).
  Future<String?> storedAccountEmail() =>
      _storage.read(key: _kAccountEmail);

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Whether automatic Drive backup is enabled (default: false until signed in).
  Future<bool> isEnabled() async {
    final raw = await _storage.read(key: _kEnabled);
    return raw == 'true';
  }

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _kEnabled, value: value.toString());

  /// Date of the most recent successful Drive upload.
  Future<DateTime?> lastBackupDate() async {
    final raw = await _storage.read(key: _kLastDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Core: Upload ──────────────────────────────────────────────────────────

  /// Uploads the database + identity + key to Drive's appDataFolder.
  Future<Result<void>> uploadBackup() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return const FailureResult(
          AuthFailure(messageAr: 'يرجى تسجيل الدخول إلى حساب Google أولاً.'),
        );
      }

      // 1. Upload the encrypted database.
      final dbPath = await DatabaseProvider.databaseFilePath();
      await _uploadFile(token, dbPath, _driveDbFileName);

      // 2. Upload the identity file if it exists.
      final docsDir = await getApplicationDocumentsDirectory();
      final identityPath = p.join(docsDir.path, _localIdentityFileName);
      if (File(identityPath).existsSync()) {
        await _uploadFile(token, identityPath, _driveIdentityFileName);
      }

      // 3. Upload the DB encryption key.
      final dbKey = await _storage.read(key: 'qayd_db_derived_key_v2');
      if (dbKey != null && dbKey.isNotEmpty) {
        final tmpDir = await getTemporaryDirectory();
        final keyPath = p.join(tmpDir.path, _driveDbKeyFileName);
        await File(keyPath).writeAsString(dbKey);
        await _uploadFile(token, keyPath, _driveDbKeyFileName);
        try {
          await File(keyPath).delete();
        } catch (_) {}
      }

      // Record the timestamp.
      await _storage.write(
        key: _kLastDate,
        value: DateTime.now().toIso8601String(),
      );

      return const Success(null);
    } catch (e) {
      return FailureResult(
        FileSystemFailure(messageAr: 'فشل رفع النسخة الاحتياطية إلى Drive: $e'),
      );
    }
  }

  /// Performs a Drive backup if [isEnabled] and no backup has run today.
  /// Safe to call every app launch.
  Future<void> performIfDue() async {
    if (!await isEnabled()) return;
    if (!isSignedIn) {
      await _googleSignIn.signInSilently();
      if (!isSignedIn) return;
    }
    final last = await lastBackupDate();
    if (last != null) {
      final today = DateTime.now();
      if (last.year == today.year &&
          last.month == today.month &&
          last.day == today.day) {
        return;
      }
    }
    await uploadBackup();
  }

  // ── Core: Restore ─────────────────────────────────────────────────────────

  /// Checks if a backup exists on Drive (without downloading).
  Future<Result<DriveBackupInfo>> checkForBackup() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return const FailureResult(
          AuthFailure(messageAr: 'يرجى تسجيل الدخول إلى حساب Google أولاً.'),
        );
      }

      final fileInfo = await _findFile(token, _driveDbFileName);
      if (fileInfo == null) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا توجد نسخة احتياطية على Drive.',
            code: 'drive_no_backup',
          ),
        );
      }

      return Success(DriveBackupInfo(
        fileId: fileInfo['id'] as String,
        lastModified: fileInfo['modifiedTime'] != null
            ? DateTime.tryParse(fileInfo['modifiedTime'] as String)
            : null,
        sizeBytes: int.tryParse('${fileInfo['size'] ?? 0}') ?? 0,
      ));
    } catch (e) {
      return FailureResult(
        FileSystemFailure(messageAr: 'فشل فحص النسخ الاحتياطية على Drive: $e'),
      );
    }
  }

  /// Downloads all backup files from Drive to a temporary directory.
  /// Returns the path to the downloaded DB file.
  Future<Result<String>> downloadBackup() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return const FailureResult(
          AuthFailure(messageAr: 'يرجى تسجيل الدخول إلى حساب Google أولاً.'),
        );
      }

      final tmpDir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final downloadDir =
          Directory(p.join(tmpDir.path, 'drive_restore_$stamp'));
      if (!downloadDir.existsSync()) await downloadDir.create(recursive: true);

      // 1. Download the database.
      final dbPath = p.join(downloadDir.path, _driveDbFileName);
      final dbOk = await _downloadFile(token, _driveDbFileName, dbPath);
      if (!dbOk) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا توجد نسخة احتياطية لقاعدة البيانات على Drive.',
            code: 'drive_no_db',
          ),
        );
      }

      // 2. Download identity file (best-effort).
      final identityPath =
          p.join(downloadDir.path, _driveIdentityFileName);
      await _downloadFile(token, _driveIdentityFileName, identityPath);

      // 3. Download DB key (best-effort).
      final keyPath = p.join(downloadDir.path, _driveDbKeyFileName);
      final keyOk = await _downloadFile(token, _driveDbKeyFileName, keyPath);
      if (keyOk) {
        final keyContent = await File(keyPath).readAsString();
        if (keyContent.isNotEmpty) {
          await _storage.write(
            key: 'qayd_db_derived_key_v2',
            value: keyContent,
          );
        }
      }

      // 4. Restore identity file to app documents.
      if (File(identityPath).existsSync()) {
        final docsDir = await getApplicationDocumentsDirectory();
        final destIdentity = p.join(docsDir.path, _localIdentityFileName);
        await File(identityPath).copy(destIdentity);
      }

      return Success(dbPath);
    } catch (e) {
      return FailureResult(
        FileSystemFailure(
          messageAr: 'فشل تحميل النسخة الاحتياطية من Drive: $e',
        ),
      );
    }
  }

  // ── Private: Auth ─────────────────────────────────────────────────────────

  /// Returns the current access token, or null if not signed in.
  Future<String?> _getAccessToken() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) return null;

    final auth = await account.authentication;
    return auth.accessToken;
  }

  Options _authHeaders(String token) => Options(
        headers: {'Authorization': 'Bearer $token'},
      );

  // ── Private: Drive API via Dio ────────────────────────────────────────────

  /// Finds a file by name in appDataFolder. Returns the file metadata or null.
  Future<Map<String, dynamic>?> _findFile(
    String token,
    String fileName,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _driveFilesUrl,
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$fileName'",
        'fields': 'files(id, name, modifiedTime, size)',
      },
      options: _authHeaders(token),
    );
    final files = (response.data?['files'] as List<dynamic>?) ?? [];
    if (files.isEmpty) return null;
    return files.first as Map<String, dynamic>;
  }

  /// Uploads a local file to appDataFolder, replacing any existing file with
  /// the same name.
  Future<void> _uploadFile(
    String token,
    String localPath,
    String driveName,
  ) async {
    final file = File(localPath);
    final fileBytes = await file.readAsBytes();

    // Check if the file already exists on Drive.
    final existing = await _findFile(token, driveName);

    if (existing != null) {
      // Update existing file content via PATCH.
      final fileId = existing['id'] as String;
      await _dio.patch<void>(
        '$_driveUploadUrl/$fileId',
        data: Stream.fromIterable([fileBytes]),
        queryParameters: {'uploadType': 'media'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/octet-stream',
            'Content-Length': fileBytes.length,
          },
        ),
      );
    } else {
      // Create new file in appDataFolder using multipart upload.
      final metadata = '{"name":"$driveName","parents":["appDataFolder"]}';
      final boundary = '===qayd_boundary_${DateTime.now().millisecondsSinceEpoch}===';

      final body = StringBuffer()
        ..write('--$boundary\r\n')
        ..write('Content-Type: application/json; charset=UTF-8\r\n\r\n')
        ..write('$metadata\r\n')
        ..write('--$boundary\r\n')
        ..write('Content-Type: application/octet-stream\r\n\r\n');

      final prefix = body.toString().codeUnits;
      final suffix = '\r\n--$boundary--'.codeUnits;

      final combined = <int>[...prefix, ...fileBytes, ...suffix];

      await _dio.post<void>(
        _driveUploadUrl,
        data: Stream.fromIterable([combined]),
        queryParameters: {'uploadType': 'multipart'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/related; boundary=$boundary',
            'Content-Length': combined.length,
          },
        ),
      );
    }
  }

  /// Downloads a file from appDataFolder to a local path.
  /// Returns false if the file does not exist on Drive.
  Future<bool> _downloadFile(
    String token,
    String driveName,
    String localPath,
  ) async {
    final fileInfo = await _findFile(token, driveName);
    if (fileInfo == null) return false;

    final fileId = fileInfo['id'] as String;
    final response = await _dio.get<List<int>>(
      '$_driveFilesUrl/$fileId',
      queryParameters: {'alt': 'media'},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.bytes,
      ),
    );

    if (response.data != null) {
      await File(localPath).writeAsBytes(response.data!);
      return true;
    }
    return false;
  }
}

/// Metadata about a backup stored on Drive.
class DriveBackupInfo {
  const DriveBackupInfo({
    required this.fileId,
    this.lastModified,
    this.sizeBytes = 0,
  });

  final String fileId;
  final DateTime? lastModified;
  final int sizeBytes;
}
