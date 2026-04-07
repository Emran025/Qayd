import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/governance/dtos/check_governance_status_input.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';

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
                'التطبيق في وضع التعليق: لا يمكن حفظ التعديلات حتى يتم استئناف الخدمة.',
            code: 'governance_suspended',
          ),
        );
      case GovernanceStatusKind.revoked:
        return FailureResult(
          ValidationFailure(
            messageAr: status.messageAr ??
                'انتهت صلاحية التفعيل. يرجى إدخال بيانات التفعيل من جديد.',
            code: 'governance_revoked',
          ),
        );
      case GovernanceStatusKind.expired:
        return FailureResult(
          ValidationFailure(
            messageAr: status.messageAr ??
                'انتهت صلاحية الاشتراك. يرجى سداد الرسوم لتفعيل التطبيق.',
            code: 'governance_expired',
          ),
        );
    }
  }
}
