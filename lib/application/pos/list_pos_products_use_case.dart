import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_product.dart';
import 'package:qayd/domain/repositories/pos_product_repository.dart';

final class ListPosProductsUseCase {
  ListPosProductsUseCase(this._repository);

  final PosProductRepository _repository;

  Future<Result<List<PosProduct>>> call({
    bool activeOnly = true,
    String? search,
  }) {
    return _repository.list(activeOnly: activeOnly, search: search);
  }
}
