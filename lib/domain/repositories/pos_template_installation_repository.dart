import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_activation_result.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';

/// Read-only access to the currently enabled, versioned POS template.
///
/// The returned account map is keyed by [PosTemplateAccountKey.value], never by
/// localized account names. Implementations must not provision or mutate data.
abstract interface class PosTemplateInstallationRepository {
  Future<Result<PosActivationResult?>> getEnabledInstallation({
    required PosTemplateDefinition template,
  });
}
