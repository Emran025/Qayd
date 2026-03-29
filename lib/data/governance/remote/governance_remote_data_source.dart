import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';

/// Backend contract for governance (HTTP client implementation later).
abstract interface class GovernanceRemoteDataSource {
  /// GET /governance/status (future); today returns stubbed status.
  Future<GovernanceStatus> fetchStatus();

  /// POST /governance/activate (future); validates license and org id.
  Future<void> submitActivation(SubmitActivationRequest request);
}
