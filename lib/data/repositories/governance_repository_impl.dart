import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/governance/remote/governance_remote_data_source.dart';
import 'package:qayd/domain/repositories/governance_repository.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';

/// Caches governance status briefly to avoid hammering the remote stub / future API.
final class GovernanceRepositoryImpl implements GovernanceRepository {
  GovernanceRepositoryImpl(this._remote);

  final GovernanceRemoteDataSource _remote;

  static const Duration _ttl = Duration(seconds: 45);

  GovernanceStatus? _cached;
  DateTime? _cachedAt;

  @override
  Future<Result<GovernanceStatus>> getStatus(
      {bool forceRefresh = false}) async {
    try {
      final now = DateTime.now();
      if (!forceRefresh &&
          _cached != null &&
          _cachedAt != null &&
          now.difference(_cachedAt!) < _ttl) {
        return Success(_cached!);
      }
      final s = await _remote.fetchStatus();
      _cached = s;
      _cachedAt = now;
      return Success(s);
    } on Object catch (_) {
      return FailureResult(
        NetworkFailure(
          messageAr: 'تعذر التحقق من حالة الترخيص. تحقق من الاتصال.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> submitActivation(SubmitActivationRequest request) async {
    try {
      await _remote.submitActivation(request);
      _cached = GovernanceStatus.activated;
      _cachedAt = DateTime.now();
      return const Success(null);
    } on ArgumentError catch (_) {
      return FailureResult(
        ValidationFailure(
          messageAr: 'يرجى إدخال معرف المنشأة ومفتاح التفعيل.',
          code: 'governance_activation_invalid_input',
        ),
      );
    } on StateError catch (_) {
      return FailureResult(
        ValidationFailure(
          messageAr: 'بيانات التفعيل غير صحيحة.',
          code: 'governance_activation_rejected',
        ),
      );
    } on Object catch (_) {
      return FailureResult(
        NetworkFailure(
          messageAr: 'تعذر إكمال التفعيل. حاول مرة أخرى.',
        ),
      );
    }
  }
}
