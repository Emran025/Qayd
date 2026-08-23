import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_product.dart';
import 'package:qayd/domain/repositories/pos_product_repository.dart';
import 'package:qayd/domain/value_objects/pos_barcode.dart';

final class FindPosProductByBarcodeUseCase {
  FindPosProductByBarcodeUseCase(this._repository);

  final PosProductRepository _repository;

  Future<Result<PosProduct?>> call(PosBarcode barcode) {
    return _repository.getByBarcode(barcode);
  }
}
