import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/data/network/sync_socket_service.dart';
import 'package:qayd/application/sync/sync_payload_processor.dart';

/// Manages multi-tiered polling and live WS connection for Real-Time Synchronization.
/// Uses [SyncRepository], [SyncSocketService], and [SyncPayloadProcessor]
/// for instantaneous two-way cryptographic verification and local database ingestion.
class SyncCoordinatorService {
  SyncCoordinatorService({
    required this.syncRepository,
    required this.socketService,
    required this.payloadProcessor,
    required this.currentUserId,
    this.syncInterval = const Duration(minutes: 10),
  });

  final SyncRepository syncRepository;
  final SyncSocketService socketService;
  final SyncPayloadProcessor payloadProcessor;
  final int currentUserId;
  final Duration syncInterval;

  Timer? _periodicTimer;
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
    });

    // 3. Periodic safe polling (for extreme resilience)
    _periodicTimer = Timer.periodic(syncInterval, (_) => _catchUpSync());
  }

  /// Stop sync lifecycle (e.g. app goes completely dormant or user logs out)
  void stop() {
    _periodicTimer?.cancel();
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
