import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/data/network/sync_socket_service.dart';
import 'package:qayd/application/sync/sync_payload_processor.dart';
import 'package:qayd/domain/services/native_notification_service.dart';
import 'package:qayd/domain/services/notification_filter_service.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/application/notifications/collateral_expiry_checker.dart';
import 'package:qayd/data/repositories/outbox_dao.dart';
import 'package:qayd/data/repositories/sync_watermark_dao.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/core/result/result.dart';

/// Manages multi-tiered polling and live WS connection for Real-Time Synchronization.
/// Uses [SyncRepository], [SyncSocketService], and [SyncPayloadProcessor]
/// for instantaneous two-way cryptographic verification and local database ingestion.
class SyncCoordinatorService {
  SyncCoordinatorService({
    required this.syncRepository,
    required this.socketService,
    required this.payloadProcessor,
    required this.nativeNotificationService,
    required this.notificationFilterService,
    required this.notificationMessageRepository,
    required this.outboxDao,
    required this.watermarkDao,
    required this.currentUserId,
    this.collateralExpiryChecker,
    this.syncInterval = const Duration(minutes: 10),
  });

  final SyncRepository syncRepository;
  final SyncSocketService socketService;
  final SyncPayloadProcessor payloadProcessor;
  final NativeNotificationService nativeNotificationService;
  final NotificationFilterService notificationFilterService;
  final NotificationMessageRepository notificationMessageRepository;
  final OutboxDao outboxDao;
  final SyncWatermarkDao watermarkDao;
  final int currentUserId;
  final CollateralExpiryChecker? collateralExpiryChecker;
  final Duration syncInterval;

  Timer? _periodicTimer;
  Timer? _expiryTimer;
  StreamSubscription? _socketSubscription;

  // Background queue state for lookups
  bool _isProcessingQueue = false;
  bool _hasPendingPull = false;

  /// Whether the coordinator is currently active.
  bool get isRunning => _periodicTimer != null || _socketSubscription != null;

  /// Initiate the synchronization lifecycle
  void start() {
    // 1. Instantly enqueue task to fetch any missed nodes while disconnected
    triggerSync();

    // 2. Connect the active WebSocket listener
    socketService.connect(currentUserId);
    _socketSubscription = socketService.incomingNodes.listen((node) async {
      // Pass the encrypted wrapper into the Crypto Engine for authentication/decryption
      await payloadProcessor.processIncomingNodes([node]);

      // Auto-acknowledge receipt to update the server's tracking state
      await _acknowledge([node.id], 'delivered');

      // Trigger Native Notification and persist to inbox if it's an important event
      // AND user has not disabled peer activity notifications.
      if (node.eventType == SyncEventType.claim) {
        if (notificationFilterService.isPeerActivityEnabled) {
          await nativeNotificationService.showImportantNotification(
            title: AppStrings.syncClaimTitle,
            body: AppStrings.syncClaimBody,
            payload: 'voucher_chat:${node.senderId}',
          );
          await notificationMessageRepository.insert(
            id: node.id,
            bodyText: AppStrings.syncClaimBody,
            counterpartyAccountId: node.senderId.toString(),
            createdAtIso: DateTime.now().toIso8601String(),
            channel: 'server',
          );
        }
      } else if (node.eventType == SyncEventType.acceptance) {
        if (notificationFilterService.isSelfActivityEnabled) {
          await nativeNotificationService.showLocalNotification(
            title: AppStrings.approved,
            body: AppStrings.yourBondHasBeen,
            payload: 'voucher_chat:${node.senderId}',
          );
          await notificationMessageRepository.insert(
            id: node.id,
            bodyText:
                'تم اعتماد سند الصرف الخاص بك (#${node.id.substring(0, 4)}).',
            counterpartyAccountId: node.senderId.toString(),
            createdAtIso: DateTime.now().toIso8601String(),
            channel: 'server',
          );
        }
      }
    });

    // 3. Periodic safe polling (for extreme resilience)
    _periodicTimer = Timer.periodic(syncInterval, (_) => triggerSync());

    // 4. Schedule collateral expiry checks (every 6 hours)
    if (collateralExpiryChecker != null) {
      // Immediate first check
      collateralExpiryChecker!.checkAndNotify();
      _expiryTimer = Timer.periodic(
        const Duration(hours: 6),
        (_) => collateralExpiryChecker!.checkAndNotify(),
      );
    }
  }

  /// Stop sync lifecycle (e.g. app goes completely dormant or user logs out)
  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    socketService.disconnect();
  }

  /// Manually requested pull-to-refresh / On-Enter Sync
  Future<void> forceSync() async {
    triggerSync();
  }

  /// Triggers a lookup operation in the background queue.
  void triggerSync() {
    _hasPendingPull = true;
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_hasPendingPull) {
        _hasPendingPull = false;
        await _catchUpSync();
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Delta fetch capturing any encrypted nodes missed while socket disconnected
  Future<void> _catchUpSync() async {
    try {
      // 1. Flush local outbox to server
      await _flushOutbox();

      // 2. Fetch server-side watermark or last sync time
      // Using a generic 'server' watermark here:
      final wmResult = await watermarkDao.getForCounterparty('server_global');
      final lastSync = wmResult.isSuccess && wmResult.valueOrNull != null
          ? wmResult.valueOrNull!.lastSyncedAt.toIso8601String()
          : null;

      // 3. Pull new nodes since last watermark
      final nodes = await syncRepository.pullNodes(since: lastSync);
      if (nodes.isNotEmpty) {
        // Feed caught-up nodes firmly into local verification pipelines
        await payloadProcessor.processIncomingNodes(nodes);

        final ids = nodes.map((e) => e.id).toList();
        await _acknowledge(ids, 'delivered');
      }
    } catch (e) {
      debugPrint('Sync Coordinator caught error during Catch-Up: $e');
    }
  }

  Future<void> _acknowledge(List<String> nodeIds, String state) async {
    try {
      await syncRepository.acknowledgeNodes(nodeIds, state);
    } catch (e) {
      debugPrint('Failed to acknowledge Delivery state: $e');
    }
  }

  /// Flushes pending entries in the Local Change Queue (Outbox) to the central server.
  Future<void> _flushOutbox() async {
    final pendingResult = await outboxDao.listPending();
    if (pendingResult.isFailure) return;

    final entries = pendingResult.valueOrNull ?? [];
    if (entries.isEmpty) return;

    final deliveredIds = <String>[];
    for (final entry in entries) {
      try {
        final node = SyncNode(
          id: entry.id,
          senderId: currentUserId,
          receiverId: int.tryParse(entry.counterpartyAccountId) ?? 0,
          eventType: _parseEventType(entry.eventType),
          encryptedPayload: entry.encryptedPayload,
          syncState: 'pending',
          clientTimestamp: entry.createdAt,
        );

        await syncRepository.pushNode(node);
        deliveredIds.add(entry.id);
      } catch (e) {
        await outboxDao.incrementRetry(entry.id);
      }
    }

    if (deliveredIds.isNotEmpty) {
      await outboxDao.markDelivered(deliveredIds, transport: 'server');
    }
  }

  SyncEventType _parseEventType(String type) {
    return SyncEventType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => SyncEventType.unknown,
    );
  }
}
