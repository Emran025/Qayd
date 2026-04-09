import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/repositories/accrual_repository.dart';

final class SaveAccrualUseCase {
  const SaveAccrualUseCase(this._repository, this._idGenerator);
  final AccrualRepository _repository;
  final IdGenerator _idGenerator;

  Future<Result<AccrualComponent>> call({
    String? id,
    required String name,
    String? description,
    required int totalAmountMinor,
    required String currencyCode,
    String? sourceAccountId,
    required String destinationAccountId,
    String? costCenterId,
    String? categoryId,
    required AccrualFrequency frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    bool isActive = true,
  }) async {
    final component = AccrualComponent(
      id: id ?? _idGenerator.next(),
      name: name.trim(),
      description: description?.trim(),
      totalAmountMinor: totalAmountMinor,
      currencyCode: currencyCode,
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      costCenterId: costCenterId,
      categoryId: categoryId,
      frequency: frequency,
      startDate: startDate,
      nextDueDate: nextDueDate,
      isActive: isActive,
      createdAt: DateTime.now(),
    );

    if (component.name.isEmpty) {
      return const FailureResult(
          ValidationFailure(messageAr: 'يرجى إدخال اسم الالتزام.'));
    }

    final result = await _repository.save(component);
    return result.fold((f) => FailureResult(f), (_) => Success(component));
  }
}
