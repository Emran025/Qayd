import 'dart:convert';

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
    final keyPair = await getCurrentKeyPair();
    if (keyPair == null) return;

    final payload = {
      'kind': 'audit_batch',
      'entries': [entry.toMap()],
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
        auditEntryId: entry.id,
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
