import 'package:qayd/domain/entities/sync_node.dart';

/// Repository for the End-to-End Encrypted (E2EE) Sync Node layer.
/// This handles pushing encrypted blocks, polling/pulling, and authenticating state.
abstract class SyncRepository {
  /// Fetch outstanding sync nodes directed at this user
  Future<List<SyncNode>> pullNodes();

  /// Push an encrypted sync node up to the server to be routed to [receiverId]
  Future<void> pushNode(SyncNode node);

  /// Mark the provided nodes to have progressed to [state] ('delivered', 'read')
  Future<void> acknowledgeNodes(List<String> nodeIds, String state);
}
