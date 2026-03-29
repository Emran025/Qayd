import 'package:qayd/application/governance/dtos/check_governance_status_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/governance_repository.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';

class CheckGovernanceStatusUseCase {
  CheckGovernanceStatusUseCase(this._repo);

  final GovernanceRepository _repo;

  Future<Result<GovernanceStatus>> call(CheckGovernanceStatusInput input) {
    return _repo.getStatus(forceRefresh: input.forceRefresh);
  }
}
