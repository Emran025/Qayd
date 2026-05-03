import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/governance/dtos/check_governance_status_input.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// Policy gate for mutating use cases: blocks writes when governance is not [GovernanceStatusKind.activated].
class GovernanceWriteGuard {
  GovernanceWriteGuard(this._checkGovernance);

  final CheckGovernanceStatusUseCase _checkGovernance;

  Future<Result<void>> assertWritesPermitted() async {
    final result = await _checkGovernance(const CheckGovernanceStatusInput());
    return result.fold(
      (f) => FailureResult(f),
      _mapStatusToWriteGate,
    );
  }

  Result<void> _mapStatusToWriteGate(GovernanceStatus status) {
    switch (status.kind) {
      case GovernanceStatusKind.activated:
        return const Success(null);
      case GovernanceStatusKind.suspended:
        return FailureResult(
          ValidationFailure(
            messageAr: status.messageAr ??
                AppStringsAr.theApplicationIsIn,
            code: 'governance_suspended',
          ),
        );
      case GovernanceStatusKind.revoked:
        return FailureResult(
          ValidationFailure(
            messageAr: status.messageAr ??
                AppStringsAr.activationHasExpiredPlease,
            code: 'governance_revoked',
          ),
        );
      case GovernanceStatusKind.expired:
        return FailureResult(
          ValidationFailure(
            messageAr: status.messageAr ??
                AppStringsAr.subscriptionHasExpiredPlease,
            code: 'governance_expired',
          ),
        );
    }
  }
}
