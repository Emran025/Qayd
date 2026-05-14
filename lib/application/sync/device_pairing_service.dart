import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/application/sync/audit_sync_compression_service.dart';
import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/application/sync/manual_link_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/device_registry_repository.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

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
    required this.database,
  });

  final DeviceSessionRepository deviceSessionRepository;
  final DeviceRegistryRepository deviceRegistryRepository;
  final AuditLogRepository auditLogRepository;
  final AuditSyncDispatcher auditSyncDispatcher;
  final CompanionLinkService companionLinkService;
  final LicenseVault licenseVault;
  final SyncCoordinatorService syncCoordinatorService;
  final Database database;

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
        role: serverSession.role,
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
      debugPrint('DevicePairing: ⚠️ No audit entries to send to $targetDeviceId.');
      return;
    }

    // §D-1: Enrich each CREATE entry with a full DB snapshot before sending.
    // Entries are often logged with partial newData (e.g. {id, state, date}).
    // The companion's _applySingle needs oldData['_parent'] to reconstruct
    // the complete row. We query the live DB here on the Primary side.
    final enriched = await Future.wait(delta.map(_enrichEntryForDispatch));

    const chunkSize = 250;
    final entriesToSend =
        enriched.length > chunkSize ? _compactSnapshot(enriched) : enriched;
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

  /// §D-1: Enriches a single [AuditEntry] with a live DB snapshot so the
  /// companion's recovery engine can reconstruct the complete row.
  ///
  /// For CREATE entries, we fetch the current row and embed it as
  /// `oldData['_parent']`. For UPDATE entries, we embed the full row
  /// in `newData`. If the row no longer exists, the entry is
  /// returned as-is (best-effort — the compact snapshot will have resolved it).
  Future<AuditEntry> _enrichEntryForDispatch(AuditEntry entry) async {
    if (entry.action != AuditAction.create && entry.action != AuditAction.update) {
      return entry;
    }
    // Already enriched (has a full DB snapshot).
    if (entry.action == AuditAction.create &&
        entry.oldData != null &&
        entry.oldData!.containsKey('_parent')) {
      return entry;
    }

    try {
      final table = AuditLogService.tableFor(entry.entityType);
      final rows = await database
          .query(table, where: 'id = ?', whereArgs: [entry.entityId]);
      if (rows.isEmpty) return entry;

      if (entry.action == AuditAction.create) {
        final enrichedOldData = <String, dynamic>{
          ...?entry.oldData,
          '_parent': rows.first,
        };
        return entry.copyWith(oldData: enrichedOldData);
      } else {
        final enrichedNewData = <String, dynamic>{
          ...rows.first,
          ...?entry.newData,
        };
        return entry.copyWith(newData: enrichedNewData);
      }
    } catch (_) {
      // Non-fatal: table might not exist for this entityType.
      return entry;
    }
  }

  List<AuditEntry> _compactSnapshot(List<AuditEntry> entries) {
    final firstByEntity = <String, AuditEntry>{};
    final deletes = <String, AuditEntry>{};

    for (final entry in entries) {
      final key = '${entry.entityType}:${entry.entityId}';
      if (entry.action == AuditAction.delete) {
        deletes[key] = entry;
      }
      if (!firstByEntity.containsKey(key)) {
        firstByEntity[key] = entry;
      }
    }

    final compacted = <AuditEntry>[];
    for (final key in firstByEntity.keys) {
      if (deletes.containsKey(key)) {
        compacted.add(deletes[key]!);
      } else {
        compacted.add(firstByEntity[key]!);
      }
    }

    compacted.sort((a, b) => (a.syncSeq ?? 0).compareTo(b.syncSeq ?? 0));
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

  /// PRIMARY DEVICE (Manual Code flow):
  /// Polls the server until the Companion enters the displayed code,
  /// then sends the bootstrap payload — same path as after QR scan.
  ///
  /// [shortCode]: the 8-char code already generated and displayed to the user.
  /// [manualLinkService]: injected to perform the polling.
  /// [approvalGate]: confirmation dialog before sending credentials.
  Future<void> sendCompanionBootstrapViaCode({
    required String shortCode,
    required ManualLinkService manualLinkService,
    required Future<bool> Function() approvalGate,
  }) async {
    if (await licenseVault.isCompanionDevice()) {
      throw StateError(
        'Companion devices are not allowed to authorize new pairings.',
      );
    }

    // Poll the server until the Companion submits their data.
    const pollInterval = Duration(seconds: 5);
    const maxAttempts = 120; // 10 minutes (120 × 5s)
    CompanionPairingData? companionData;

    for (var i = 0; i < maxAttempts; i++) {
      companionData = await manualLinkService.pollForCompanionData(shortCode: shortCode);
      if (companionData != null) break;
      await Future<void>.delayed(pollInterval);
    }

    if (companionData == null) {
      throw StateError('Timed out waiting for Companion to enter the code.');
    }

    // Approval gate — ask the Primary user to confirm linking.
    final approved = await approvalGate();
    if (!approved) {
      throw StateError('Companion linking cancelled by user.');
    }

    // Cancel previous discovery and start a new one.
    _discoveryCancel?.complete();
    _discoveryCancel = Completer<void>();
    final cancel = _discoveryCancel!;

    final sessionsBefore = await deviceSessionRepository.listAll();
    final knownDeviceIds = sessionsBefore.map((s) => s.deviceId).toSet();
    final bridgeStartedAt = DateTime.now().toUtc();

    await companionLinkService.sendBootstrapToCompanionViaCode(
      companionData: companionData,
    );

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
