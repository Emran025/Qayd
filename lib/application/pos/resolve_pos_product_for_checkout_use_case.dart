import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_product.dart';
import 'package:qayd/domain/repositories/pos_product_repository.dart';
import 'package:qayd/domain/value_objects/pos_barcode.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// Resolves keyboard, camera, and manual search input through one application API.
final class ResolvePosProductForCheckoutUseCase {
  const ResolvePosProductForCheckoutUseCase(this._repository);

  final PosProductRepository _repository;

  Future<Result<PosProduct>> call(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return FailureResult(
        ValidationFailure(
          messageAr: AppStrings.posProductNotFound,
          code: 'pos_checkout_query_empty',
        ),
      );
    }

    final barcodeResult = await _tryBarcode(query);
    if (barcodeResult != null) return Success(barcodeResult);

    final results = await _repository.list(search: query, activeOnly: true);
    if (results.isFailure) return FailureResult(results.failureOrNull!);
    final products = results.valueOrNull!;
    if (products.length == 1) return Success(products.single);
    return FailureResult(
      ValidationFailure(
        messageAr: AppStrings.posProductNotFound,
        code: products.isEmpty
            ? 'pos_checkout_product_not_found'
            : 'pos_checkout_product_ambiguous',
      ),
    );
  }

  Future<PosProduct?> _tryBarcode(String query) async {
    try {
      final result = await _repository.getByBarcode(PosBarcode(query));
      if (result.isFailure) return null;
      return result.valueOrNull;
    } catch (_) {
      return null;
    }
  }
}
