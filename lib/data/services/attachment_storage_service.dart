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

  /// Decrypts an image into a raw byte buffer for display.
  Future<Uint8List> decrypt(VoucherAttachment attachment) async {
    final encryptionKeyHex = await _keyProvider.obtainKey();
    final rawKey = _hexToBytes(encryptionKeyHex);
    final aesKey = Uint8List.fromList(sha256.convert(rawKey).bytes);
    final aesIv = Uint8List.fromList(
        sha256.convert(utf8.encode('attachment_iv')).bytes.sublist(0, 16));

    final encryptedBytes = await File(attachment.storagePath).readAsBytes();
    return _encryptor.decrypt(
        Uint8List.fromList(encryptedBytes), aesKey, aesIv);
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
