import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/pos_product_repository.dart';

final class DeactivatePosProductUseCase {
  DeactivatePosProductUseCase(this._repository, this._writeGuard);

  final PosProductRepository _repository;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<void>> call(String productId) async {
    final gate = await _writeGuard.assertWritesPermitted();
    if (gate.isFailure) return FailureResult(gate.failureOrNull!);
    return _repository.deactivate(productId);
  }
}
