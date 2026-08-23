import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_product.dart';
import 'package:qayd/domain/value_objects/pos_barcode.dart';

/// Persistence port for the POS product aggregate.
abstract interface class PosProductRepository {
  Future<Result<PosProduct>> getById(String id);

  Future<Result<PosProduct?>> getByBarcode(PosBarcode barcode);

  Future<Result<List<PosProduct>>> list({
    bool activeOnly = true,
    String? search,
  });

  Future<Result<void>> save(PosProduct product);

  Future<Result<void>> deactivate(String id);
}
