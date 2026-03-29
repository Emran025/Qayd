import 'package:qayd/application/governance/dtos/submit_activation_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/governance_repository.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';

class SubmitActivationUseCase {
  SubmitActivationUseCase(this._repo);

  final GovernanceRepository _repo;

  Future<Result<void>> call(SubmitActivationInput input) {
    return _repo.submitActivation(
      SubmitActivationRequest(
        organizationId: input.organizationId.trim(),
        licenseKey: input.licenseKey.trim(),
      ),
    );
  }
}
