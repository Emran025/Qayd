import 'package:qayd/data/governance/remote/governance_remote_data_source.dart';
import 'package:qayd/data/governance/remote/governance_stub_controller.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';

/// Simulates latency and API shape until a real [GovernanceRemoteDataSource] exists.
final class StubGovernanceRemoteDataSource implements GovernanceRemoteDataSource {
  StubGovernanceRemoteDataSource({required GovernanceStubController controller})
      : _controller = controller;

  final GovernanceStubController _controller;

  static const Duration _latency = Duration(milliseconds: 450);

  @override
  Future<GovernanceStatus> fetchStatus() async {
    await Future<void>.delayed(_latency);
    return _controller.remoteStatus;
  }

  @override
  Future<void> submitActivation(SubmitActivationRequest request) async {
    await Future<void>.delayed(_latency);
    if (_controller.rejectNextActivation) {
      throw StateError('governance_activation_rejected');
    }
    if (request.organizationId.trim().isEmpty ||
        request.licenseKey.trim().isEmpty) {
      throw ArgumentError('activation_fields_required');
    }
    _controller.remoteStatus = const GovernanceStatus(kind: GovernanceStatusKind.activated);
  }
}
