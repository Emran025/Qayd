import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_activation_result.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';
import 'package:qayd/domain/repositories/pos_activation_repository.dart';

/// Explicit user-opt-in operation that installs and enables the POS template.
final class ActivatePosFeatureUseCase {
  ActivatePosFeatureUseCase(
    this._repository,
    this._writeGuard, {
    PosTemplateDefinition? template,
  }) : _template = template ?? PosTemplateDefinition.current();

  final PosActivationRepository _repository;
  final GovernanceWriteGuard _writeGuard;
  final PosTemplateDefinition _template;

  Future<Result<PosActivationResult>> call({required String deviceId}) async {
    final gate = await _writeGuard.assertWritesPermitted();
    if (gate.isFailure) {
      return FailureResult(gate.failureOrNull!);
    }

    return _repository.installTemplate(
      template: _template,
      now: DateTime.now().toUtc(),
      deviceId: deviceId,
    );
  }
}
