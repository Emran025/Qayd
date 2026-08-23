import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_activation_result.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';

/// Persistence port for the explicit, opt-in POS template installation.
abstract interface class PosActivationRepository {
  Future<Result<PosActivationResult>> installTemplate({
    required PosTemplateDefinition template,
    required DateTime now,
    required String deviceId,
  });

  Future<Result<bool>> isEnabled();

  Future<Result<String?>> getEnabledWarehouseId();

  Future<Result<void>> disable();
}
