import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qayd/application/sync/audit_sync_compression_service.dart';
import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/device_registry_repository.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';

import 'package:qayd/application/sync/sync_coordinator_service.dart';

class DevicePairingService {
  DevicePairingService({
    required this.deviceSessionRepository,
    required this.deviceRegistryRepository,
    required this.auditLogRepository,
    required this.auditSyncDispatcher,
    required this.companionLinkService,
    required this.licenseVault,
    required this.syncCoordinatorService,
  });

  final DeviceSessionRepository deviceSessionRepository;
  final DeviceRegistryRepository deviceRegistryRepository;
  final AuditLogRepository auditLogRepository;
  final AuditSyncDispatcher auditSyncDispatcher;
  final CompanionLinkService companionLinkService;
  final LicenseVault licenseVault;
  final SyncCoordinatorService syncCoordinatorService;

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
    if (session == null || !session.isActive) {
      return;
    }

    final delta = await auditLogRepository.listSinceSeq(session.lastSyncSeq);
    if (delta.isEmpty) {
      return;
    }

    const chunkSize = 250;
    final entriesToSend =
        delta.length > chunkSize ? _compactSnapshot(delta) : delta;
    final totalBatches = (entriesToSend.length / chunkSize).ceil();
    int batchIndex = 1;

    for (var i = 0; i < entriesToSend.length; i += chunkSize) {
      final end = (i + chunkSize < entriesToSend.length)
          ? i + chunkSize
          : entriesToSend.length;
      final chunk = entriesToSend.sublist(i, end);
      final isLast = end >= entriesToSend.length;

      await auditSyncDispatcher.dispatchBatchToDevice(
        entries: chunk,
        targetDeviceId: targetDeviceId,
        receiverPublicKeyHex: session.publicKeyHex,
        isLastBatch: isLast,
        batchIndex: batchIndex,
        totalBatches: totalBatches,
        reason: SyncPacketReason.initialBootstrap,
      );
      batchIndex++;
    }

    final maxSeq = delta.last.syncSeq;
    if (maxSeq != null) {
      await deviceSessionRepository.updateLastSyncSeq(targetDeviceId, maxSeq);
    }
    await deviceSessionRepository.updateLastSeen(
        targetDeviceId, DateTime.now());

    unawaited(syncCoordinatorService.forceSync());
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
    const maxAttempts = 12;
    const pollInterval = Duration(seconds: 10);

    debugPrint(
        'DevicePairing: 🔍 Starting discovery loop (Bridge start: $bridgeStartedAt)');

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // Check cancellation before each poll.
      if (cancel.isCompleted) {
        debugPrint(
            'DevicePairing: ⏹ Discovery loop cancelled (new QR initiated).');
        return;
      }

      debugPrint(
          'DevicePairing: ⏳ Poll attempt ${attempt + 1}/$maxAttempts...');
      await Future<void>.delayed(pollInterval);

      if (cancel.isCompleted) return;

      try {
        await refreshSessionsFromServer();
      } catch (e) {
        debugPrint('DevicePairing: ⚠️ Network error during discovery poll: $e');
        // Continue to the next attempt, don't crash the loop.
      }

      final sessions = await deviceSessionRepository.listAll();
      debugPrint(
          'DevicePairing: Polling... total sessions in DB: ${sessions.length}');

      final targets = sessions.where((session) {
        if (!session.isActive) return false;

        // In emulator environments, device_id might be identical.
        // We allow pairing if the public key is newly discovered, 
        // even if it reports as isCurrent due to ID collision.
        final isNewlyDiscovered = !knownDeviceIds.contains(session.publicKeyHex) && 
                                 !knownDeviceIds.contains(session.deviceId);

        final looksFresh = session.lastSyncSeq <= 0 &&
            session.pairedAt
                .toUtc()
                .isAfter(bridgeStartedAt.subtract(const Duration(minutes: 2)));

        if (isNewlyDiscovered || looksFresh) {
          debugPrint('DevicePairing: ✨ Candidate found! [ID: ${session.deviceId}, New: $isNewlyDiscovered, Fresh: $looksFresh]');
          return true;
        }
        return false;
      }).toList();

      for (final target in targets) {
        if (cancel.isCompleted) return;
        debugPrint('DevicePairing: 🎯 Found target companion: ${target.deviceId}. Dispatching snapshot...');
        await dispatchInitialSnapshot(target.deviceId);
        
        // Track both ID and Key to avoid re-triggering
        knownDeviceIds.add(target.publicKeyHex);
        knownDeviceIds.add(target.deviceId);
      }

      if (targets.isNotEmpty) {
        debugPrint(
            'DevicePairing: ✅ Companion(s) discovered and snapshot(s) dispatched.');
        return;
      }

      // Update known IDs to avoid re-triggering for already handled devices in next poll
      knownDeviceIds.addAll(sessions.map((s) => s.deviceId));
    }
    debugPrint(
        'DevicePairing: ❌ Companion not discovered within polling window.');
  }
}
