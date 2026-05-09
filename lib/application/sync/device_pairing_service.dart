import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/device_registry_repository.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';

class DevicePairingService {
  DevicePairingService({
    required this.deviceSessionRepository,
    required this.deviceRegistryRepository,
    required this.auditLogRepository,
    required this.auditSyncDispatcher,
    required this.companionLinkService,
    required this.licenseVault,
  });

  final DeviceSessionRepository deviceSessionRepository;
  final DeviceRegistryRepository deviceRegistryRepository;
  final AuditLogRepository auditLogRepository;
  final AuditSyncDispatcher auditSyncDispatcher;
  final CompanionLinkService companionLinkService;
  final LicenseVault licenseVault;

  // Cancellation token for the companion discovery loop.
  // Cancelled when a new bootstrap is initiated, so the old loop exits cleanly.
  Completer<void>? _discoveryCancel;

  Future<void> pairDevice({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
    required bool isCurrent,
  }) async {
    final signedChallenge =
        'bootstrap:${DateTime.now().millisecondsSinceEpoch}:$deviceId:$publicKeyHex';
    final serverSession = await deviceRegistryRepository.pairDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      publicKeyHex: publicKeyHex,
      signedChallenge: signedChallenge,
    );
    await deviceSessionRepository.upsert(
      DeviceSession(
        deviceId: serverSession.deviceId,
        deviceName: serverSession.deviceName,
        publicKeyHex: serverSession.publicKeyHex,
        pairedAt: serverSession.pairedAt,
        lastSyncSeq: serverSession.lastSyncSeq,
        lastSeenAt: serverSession.lastSeenAt,
        isCurrent: isCurrent,
        isActive: serverSession.isActive,
      ),
    );
  }

  Future<void> dispatchInitialSnapshot(String targetDeviceId) async {
    final session = await deviceSessionRepository.getById(targetDeviceId);
    if (session == null || !session.isActive) return;
    final delta = await auditLogRepository.listSinceSeq(session.lastSyncSeq);
    if (delta.isEmpty) return;

    const chunkSize = 500;
    final entriesToSend =
        delta.length > chunkSize ? _compactSnapshot(delta) : delta;
    for (var i = 0; i < entriesToSend.length; i += chunkSize) {
      final end = (i + chunkSize < entriesToSend.length)
          ? i + chunkSize
          : entriesToSend.length;
      final chunk = entriesToSend.sublist(i, end);
      await auditSyncDispatcher.dispatchBatchToDevice(
        entries: chunk,
        targetDeviceId: targetDeviceId,
        receiverPublicKeyHex: session.publicKeyHex,
      );
    }

    final maxSeq = delta.last.syncSeq;
    if (maxSeq != null) {
      await deviceSessionRepository.updateLastSyncSeq(targetDeviceId, maxSeq);
    }
    await deviceSessionRepository.updateLastSeen(
        targetDeviceId, DateTime.now());
  }

  List<AuditEntry> _compactSnapshot(List<AuditEntry> entries) {
    final latestByEntity = <String, AuditEntry>{};
    for (final entry in entries) {
      latestByEntity['${entry.entityType}:${entry.entityId}'] = entry;
    }
    final compacted = latestByEntity.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return compacted;
  }

  Future<void> sendCompanionBootstrap({
    required String scannedQr,
    required Future<bool> Function() approvalGate,
  }) async {
    if (await licenseVault.isCompanionDevice()) {
      throw StateError(
        'Companion devices are not allowed to authorize new pairings.',
      );
    }
    final approved = await approvalGate();
    if (!approved) {
      throw StateError('Companion linking cancelled by user.');
    }

    // Cancel any in-progress discovery from a previous QR session.
    _discoveryCancel?.complete();
    _discoveryCancel = Completer<void>();
    final cancel = _discoveryCancel!;

    final sessionsBefore = await deviceSessionRepository.listAll();
    final knownDeviceIds = sessionsBefore.map((s) => s.deviceId).toSet();
    final bridgeStartedAt = DateTime.now().toUtc();
    await companionLinkService.sendBootstrapToCompanion(scannedQr: scannedQr);
    unawaited(
      _discoverCompanionAndDispatchSnapshot(
        knownDeviceIds: knownDeviceIds,
        bridgeStartedAt: bridgeStartedAt,
        cancel: cancel,
      ),
    );
  }

  Future<void> refreshSessionsFromServer() async {
    final sessions = await deviceRegistryRepository.listDevices();
    for (final session in sessions) {
      await deviceSessionRepository.upsert(session);
    }
  }

  Future<void> revokeDevice(String deviceId) async {
    await deviceRegistryRepository.revokeDevice(deviceId);
    await deviceSessionRepository.setActive(deviceId, false);
  }

  Future<void> _discoverCompanionAndDispatchSnapshot({
    required Set<String> knownDeviceIds,
    required DateTime bridgeStartedAt,
    required Completer<void> cancel,
  }) async {
    const maxAttempts = 20;
    const pollInterval = Duration(seconds: 3);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // Check cancellation before each poll.
      if (cancel.isCompleted) {
        debugPrint('DevicePairing: Discovery loop cancelled (new QR initiated).');
        return;
      }

      await Future<void>.delayed(pollInterval);

      if (cancel.isCompleted) return;

      await refreshSessionsFromServer();
      final sessions = await deviceSessionRepository.listAll();
      final targets = sessions.where((session) {
        if (!session.isActive || session.isCurrent) return false;
        final isNewlyDiscovered = !knownDeviceIds.contains(session.deviceId);
        final looksFresh = session.lastSyncSeq <= 0 &&
            session.pairedAt
                .toUtc()
                .isAfter(bridgeStartedAt.subtract(const Duration(minutes: 2)));
        return isNewlyDiscovered || looksFresh;
      }).toList();

      for (final target in targets) {
        if (cancel.isCompleted) return;
        await dispatchInitialSnapshot(target.deviceId);
        knownDeviceIds.add(target.deviceId);
      }
      if (targets.isNotEmpty) {
        debugPrint('DevicePairing: Companion discovered and snapshot dispatched.');
        return;
      }
      knownDeviceIds.addAll(sessions.map((s) => s.deviceId));
    }
    debugPrint('DevicePairing: Companion not discovered within polling window.');
  }
}

