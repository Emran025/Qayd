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
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/application/sync/sync_event_dispatcher.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_query_filter.dart';
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
    required this.voucherRepository,
    required this.syncEventDispatcher,
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
  final VoucherRepository voucherRepository;
  final SyncEventDispatcher syncEventDispatcher;
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
      // 1. Attempt to discover identities and enqueue vouchers that failed initial sync
      await _reSyncUnsyncedVouchers();

      // 2. Flush local outbox to server
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
      debugPrint('Sync: ❌ Catch-Up error: $e');
    }
  }

  /// Scans for confirmed vouchers that were never enqueued to the outbox
  /// (usually due to a missing public key during creation).
  Future<void> _reSyncUnsyncedVouchers() async {
    try {
      debugPrint('Sync: 🔍 Scanning for unsynced vouchers...');
      
      // Fetch vouchers that are confirmed but might be missing from outbox
      final filter = VoucherQueryFilter(state: VoucherState.confirmed);
      final vouchersRes = await voucherRepository.getAll(filter: filter);
      if (vouchersRes.isFailure) return;

      final vouchers = vouchersRes.valueOrNull ?? [];
      for (final voucher in vouchers) {
        // Check if a 'claim' event exists in outbox for this voucher
        final exists = await outboxDao.exists(voucher.id.value, 'claim');
        if (!exists) {
          debugPrint('Sync: ♻️ Re-attempting identity discovery for voucher ${voucher.id.value}');
          // This will attempt E2EE encryption and outbox enqueueing.
          // If the public key is still missing, it will return FailureResult.
          await syncEventDispatcher.dispatchVoucherClaim(voucher);
        }
      }
    } catch (e) {
      debugPrint('Sync: ❌ Unsynced scan error: $e');
    }
  }

  Future<void> _acknowledge(List<String> nodeIds, String state) async {
    try {
      await syncRepository.acknowledgeNodes(nodeIds, state);
    } catch (e) {
      debugPrint('Sync: ❌ Acknowledge error: $e');
    }
  }

  /// Flushes pending entries in the Local Change Queue (Outbox) to the central server.
  ///
  /// §5.C — Flexible Routing: Constructs the SyncNode with all available routing
  /// hints captured during identity discovery. The server resolves the receiver
  /// from these hints without decrypting the payload.
  Future<void> _flushOutbox() async {
    final pendingResult = await outboxDao.listPending();
    if (pendingResult.isFailure) return;

    final entries = pendingResult.valueOrNull ?? [];
    if (entries.isEmpty) return;

    final deliveredIds = <String>[];
    for (final entry in entries) {
      try {
        // §5.C: Build routing-aware SyncNode from stored hints.
        // Skip entries that have NO routing hint — they cannot be delivered
        // and would cause a 422. They will be retried after identity discovery.
        final hasHint = (entry.receiverServerId != null) ||
            (entry.receiverPhone?.isNotEmpty ?? false) ||
            (entry.receiverWhatsapp?.isNotEmpty ?? false) ||
            (entry.receiverPublicKey?.isNotEmpty ?? false);

        if (!hasHint) {
          debugPrint(
              'Sync: ⏭ Skipping ${entry.id} — no routing hint yet. Will retry after discovery.');
          continue;
        }

        final node = SyncNode(
          id: entry.id,
          senderId: currentUserId,
          // §5.C Routing headers — server picks first non-null in resolution order
          receiverId: entry.receiverServerId,
          receiverPhone: entry.receiverPhone,
          receiverWhatsapp: entry.receiverWhatsapp,
          receiverPublicKey: entry.receiverPublicKey,
          eventType: _parseEventType(entry.eventType),
          encryptedPayload: entry.encryptedPayload,
          syncState: 'pending',
          clientTimestamp: entry.createdAt,
        );

        await syncRepository.pushNode(node);
        deliveredIds.add(entry.id);
        debugPrint('Sync: ✅ Pushed node ${entry.id} (${entry.eventType}) '
            '[routed via: ${_describeRoute(entry)}]');
      } catch (e) {
        debugPrint('Sync: ❌ Push failed for ${entry.id}: $e');
        await outboxDao.incrementRetry(entry.id);
      }
    }

    if (deliveredIds.isNotEmpty) {
      await outboxDao.markDelivered(deliveredIds, transport: 'server');
    }
  }

  /// Returns a human-readable routing description for debug logs.
  String _describeRoute(OutboxEntry entry) {
    if (entry.receiverServerId != null) return 'serverId=${entry.receiverServerId}';
    if (entry.receiverPhone?.isNotEmpty ?? false) return 'phone=${entry.receiverPhone}';
    if (entry.receiverWhatsapp?.isNotEmpty ?? false) return 'whatsapp=${entry.receiverWhatsapp}';
    if (entry.receiverPublicKey?.isNotEmpty ?? false) return 'pubkey=${entry.receiverPublicKey!.substring(0, 8)}...';
    return 'none';
  }

  SyncEventType _parseEventType(String type) {
    return SyncEventType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => SyncEventType.unknown,
    );
  }
}
