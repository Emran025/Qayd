import 'dart:convert';
import 'dart:io';

import 'package:qayd/data/repositories/device_sync_outbox_dao.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:uuid/uuid.dart';

class AuditSyncDispatcher {
  AuditSyncDispatcher({
    required this.outboxDao,
    required this.e2eeService,
    required this.getCurrentKeyPair,
  });

  final DeviceSyncOutboxDao outboxDao;
  final E2EEEncryptionService e2eeService;
  final Future<CryptoKeyPair?> Function() getCurrentKeyPair;

  Future<void> dispatchEntryToDevice({
    required AuditEntry entry,
    required String targetDeviceId,
    required String receiverPublicKeyHex,
  }) async {
    await dispatchBatchToDevice(
      entries: [entry],
      targetDeviceId: targetDeviceId,
      receiverPublicKeyHex: receiverPublicKeyHex,
    );
  }

  Future<void> dispatchBatchToDevice({
    required List<AuditEntry> entries,
    required String targetDeviceId,
    required String receiverPublicKeyHex,
  }) async {
    if (entries.isEmpty) return;
    final keyPair = await getCurrentKeyPair();
    if (keyPair == null) return;

    final entriesJson =
        utf8.encode(jsonEncode(entries.map((e) => e.toMap()).toList()));
    final compressed = gzip.encode(entriesJson);
    final payload = {
      'kind': 'audit_batch',
      'encoding': 'gzip+base64',
      'entries_gzip': base64Encode(compressed),
      'entry_count': entries.length,
    };
    final encrypted = await e2eeService.encryptPayload(
      rawPayload: payload,
      senderKeyPair: keyPair,
      receiverPublicKeyHex: receiverPublicKeyHex,
    );

    final envelope = '$targetDeviceId|$encrypted';
    final signature = base64Encode(utf8.encode(envelope));
    await outboxDao.enqueue(
      DeviceSyncOutboxEntry(
        id: const Uuid().v4(),
        auditEntryId: entries.first.id,
        targetDeviceId: targetDeviceId,
        encryptedPayload: encrypted,
        signature: signature,
        state: 'pending',
        retryCount: 0,
        createdAt: DateTime.now(),
      ),
    );
  }
}
