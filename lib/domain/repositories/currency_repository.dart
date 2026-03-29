import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

/// Persistence contract for currency management.
///
/// All currency types (real, virtual, user-defined) are treated identically.
abstract interface class CurrencyRepository {
  /// Retrieve all currencies (predefined + user-defined).
  Future<Result<List<CurrencyCode>>> getAll();

  /// Retrieve a single currency by code.
  Future<Result<CurrencyCode?>> getByCode(String code);

  /// Create or update a currency.
  Future<Result<void>> save(CurrencyCode currency, {bool isPredefined = false});

  /// Delete a user-defined currency (must not be in use).
  Future<Result<void>> delete(String code);

  /// Retrieve the current base currency code.
  Future<Result<String>> getBaseCurrencyCode();

  /// Set the base currency code.
  Future<Result<void>> setBaseCurrencyCode(String code);
}
