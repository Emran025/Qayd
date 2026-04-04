import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/data/network/sync_socket_service.dart';
import 'package:qayd/application/sync/sync_payload_processor.dart';
import 'package:qayd/domain/services/native_notification_service.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/application/notifications/collateral_expiry_checker.dart';

/// Manages multi-tiered polling and live WS connection for Real-Time Synchronization.
/// Uses [SyncRepository], [SyncSocketService], and [SyncPayloadProcessor]
/// for instantaneous two-way cryptographic verification and local database ingestion.
class SyncCoordinatorService {
  SyncCoordinatorService({
    required this.syncRepository,
    required this.socketService,
    required this.payloadProcessor,
    required this.nativeNotificationService,
    required this.notificationMessageRepository,
    required this.currentUserId,
    this.collateralExpiryChecker,
    this.syncInterval = const Duration(minutes: 10),
  });

  final SyncRepository syncRepository;
  final SyncSocketService socketService;
  final SyncPayloadProcessor payloadProcessor;
  final NativeNotificationService nativeNotificationService;
  final NotificationMessageRepository notificationMessageRepository;
  final int currentUserId;
  final CollateralExpiryChecker? collateralExpiryChecker;
  final Duration syncInterval;

  Timer? _periodicTimer;
  Timer? _expiryTimer;
  StreamSubscription? _socketSubscription;

  /// Initiate the synchronization lifecycle
  void start() {
    // 1. Instantly fetch any missed nodes while disconnected
    _catchUpSync();

    // 2. Connect the active WebSocket listener
    socketService.connect(currentUserId);
    _socketSubscription = socketService.incomingNodes.listen((node) async {
      
      // Pass the encrypted wrapper into the Crypto Engine for authentication/decryption
      await payloadProcessor.processIncomingNodes([node]);
      
      // Auto-acknowledge receipt to update the server's tracking state
      await _acknowledge([node.id], 'delivered');

      // Trigger Native Notification and persist to inbox if it's an important event
      if (node.eventType == SyncEventType.claim) {
         await nativeNotificationService.showImportantNotification(
           title: 'طلب جديد',
           body: 'تم استلام طلب سند جديد من شريكك.',
         );
         await notificationMessageRepository.insert(
           id: node.id,
           bodyText: 'تم استلام طلب سند جديد من شريكك.',
           counterpartyAccountId: node.senderId.toString(),
           createdAtIso: DateTime.now().toIso8601String(),
           channel: 'server',
         );
      } else if (node.eventType == SyncEventType.acceptance) {
         await nativeNotificationService.showLocalNotification(
           title: 'تم الاعتماد',
           body: 'تم قبول السند الخاص بك ومزامنته.',
         );
         await notificationMessageRepository.insert(
           id: node.id,
           bodyText: 'تم اعتماد سند الصرف الخاص بك (#${node.id.substring(0, 4)}).',
           counterpartyAccountId: node.senderId.toString(),
           createdAtIso: DateTime.now().toIso8601String(),
           channel: 'server',
         );
      }
    });

    // 3. Periodic safe polling (for extreme resilience)
    _periodicTimer = Timer.periodic(syncInterval, (_) => _catchUpSync());

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
    _expiryTimer?.cancel();
    _socketSubscription?.cancel();
    socketService.disconnect();
  }

  /// Manually requested pull-to-refresh / On-Enter Sync
  Future<void> forceSync() async {
    await _catchUpSync();
  }

  /// Delta fetch capturing any encrypted nodes missed while socket disconnected
  Future<void> _catchUpSync() async {
    try {
      final nodes = await syncRepository.pullNodes();
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
}
