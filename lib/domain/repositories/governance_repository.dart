import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';

/// Port for tenant governance / licensing (remote-backed; local cache in impl).
abstract interface class GovernanceRepository {
  /// Latest known status; [forceRefresh] bypasses short-lived cache.
  Future<Result<GovernanceStatus>> getStatus({bool forceRefresh = false});

  /// Submits activation; on success repository should treat status as activated.
  Future<Result<void>> submitActivation(SubmitActivationRequest request);
}
