import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';

class ApiSyncRepository implements SyncRepository {
  const ApiSyncRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<SyncNode>> pullNodes({String? since}) async {
    try {
      final endpoint = since != null
          ? '${ApiEndpoints.syncPull}?since=$since'
          : ApiEndpoints.syncPull;
      final response = await _apiClient.get(endpoint);
      if (response is List) {
        return response
            .map((e) => SyncNode.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is AuthException) rethrow; // Ensure AuthExceptions bubble up
      throw Exception('Failed to pull sync nodes.');
    }
  }

  @override
  Future<void> pushNode(SyncNode node) async {
    try {
      await _apiClient.post(
        ApiEndpoints.syncPush,
        body: node.toJson(),
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw Exception('Failed to push sync node.');
    }
  }

  @override
  Future<void> acknowledgeNodes(List<String> nodeIds, String state) async {
    if (nodeIds.isEmpty) return;
    try {
      await _apiClient.post(
        ApiEndpoints.syncAcknowledge,
        body: {
          'node_ids': nodeIds,
          'state': state,
        },
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw Exception('Failed to acknowledge sync nodes.');
    }
  }
}
