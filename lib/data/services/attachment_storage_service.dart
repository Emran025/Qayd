import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:qayd/data/database/database_encryption_key_provider.dart';
import 'package:qayd/data/encryption/file_encryptor.dart';
import 'package:qayd/data/file_system/backup_file_manager.dart';
import 'package:qayd/domain/entities/voucher_attachment.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:uuid/uuid.dart';

/// Orchestrates secure storage of voucher images.
///
/// Responsibilities:
/// - Encrypts raw images using the database encryption key.
/// - Stores encrypted blobs in the persistent media directory.
/// - Generates unique hashes for content-blind deduplication.
class AttachmentStorageService {
  AttachmentStorageService({
    required DatabaseEncryptionKeyProvider keyProvider,
    BackupFileManager fileManager = const BackupFileManager(),
    FileEncryptor encryptor = const FileEncryptor(),
  })  : _keyProvider = keyProvider,
        _fileManager = fileManager,
        _encryptor = encryptor;

  final DatabaseEncryptionKeyProvider _keyProvider;
  final BackupFileManager _fileManager;
  final FileEncryptor _encryptor;

  /// Encrypts and stores a picked [source] image for the given [voucherId].
  Future<VoucherAttachment> store(
    XFile source,
    VoucherId voucherId,
  ) async {
    final imagesDir = await _fileManager.externalImagesDir();
    final encryptionKeyHex = await _keyProvider.obtainKey();

    // Derive AES key/IV from the DB passphrase
    final rawKey = _hexToBytes(encryptionKeyHex);
    final aesKey = Uint8List.fromList(sha256.convert(rawKey).bytes);
    final aesIv = Uint8List.fromList(
        sha256.convert(utf8.encode('attachment_iv')).bytes.sublist(0, 16));

    final id = const Uuid().v4();
    final ext = p.extension(source.path);
    final encryptedFileName = 'img_${id}_enc$ext';
    final destPath = p.join(imagesDir!.path, encryptedFileName);

    // 1. Encrypt and save to storage
    await _encryptor.encryptFile(source.path, destPath, aesKey, aesIv);

    // 2. Hash the encrypted blob for record-keeping
    final encryptedBytes = await File(destPath).readAsBytes();
    final blobHash = sha256.convert(encryptedBytes).toString();

    // 3. Obtain metadata
    final originalSize = await source.length();
    final mimeType = source.mimeType ?? _inferMimeType(ext);

    return VoucherAttachment(
      id: AttachmentId(id),
      voucherId: voucherId,
      fileName: source.name,
      storagePath: destPath,
      encryptedBlobHash: blobHash,
      mimeType: mimeType,
      byteSize: originalSize,
      sourceType: AttachmentSourceType.gallery,
      createdAt: DateTime.now(),
    );
  }

  /// Decrypts an attachment into a raw byte buffer for display or export.
  ///
  /// If [attachment.storagePath] no longer exists on disk (e.g. the app was
  /// reinstalled and the external storage path changed), this falls back to
  /// searching for the same file by name in the current [externalImagesDir].
  Future<Uint8List> decrypt(VoucherAttachment attachment) async {
    final encryptionKeyHex = await _keyProvider.obtainKey();
    final rawKey = _hexToBytes(encryptionKeyHex);
    final aesKey = Uint8List.fromList(sha256.convert(rawKey).bytes);
    final aesIv = Uint8List.fromList(
        sha256.convert(utf8.encode('attachment_iv')).bytes.sublist(0, 16));

    // Resolve the actual file path — fallback if the stored path is stale
    final resolvedPath = await _resolvePath(attachment.storagePath);
    final encryptedBytes = await File(resolvedPath).readAsBytes();
    return _encryptor.decrypt(
        Uint8List.fromList(encryptedBytes), aesKey, aesIv);
  }

  /// Resolves [storedPath] to an existing file.
  ///
  /// 1. Returns [storedPath] if the file exists (happy path).
  /// 2. Falls back to `externalImagesDir/<filename>` if available.
  /// 3. Returns [storedPath] unchanged so the caller gets a descriptive
  ///    FileSystemException rather than a silent wrong-path error.
  Future<String> _resolvePath(String storedPath) async {
    if (File(storedPath).existsSync()) return storedPath;

    // Try the current images directory with the same filename
    final fileName = p.basename(storedPath);
    final imagesDir = await _fileManager.externalImagesDir();
    if (imagesDir != null) {
      final candidate = p.join(imagesDir.path, fileName);
      if (File(candidate).existsSync()) return candidate;
    }

    // Return original — caller gets a meaningful error
    return storedPath;
  }

  Uint8List _hexToBytes(String hex) {
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  String _inferMimeType(String ext) {
    return switch (ext.toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}
