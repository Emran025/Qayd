import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/pos/create_pos_product_use_case.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/pos/deactivate_pos_product_use_case.dart';
import 'package:qayd/application/pos/list_pos_products_use_case.dart';
import 'package:qayd/application/pos/save_pos_product_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/pos_product.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/governance_repository.dart';
import 'package:qayd/domain/repositories/pos_product_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_barcode.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';
import 'package:qayd/presentation/pos/pos_catalog_cubit.dart';

final class _IdGenerator implements IdGenerator {
  @override
  String next() => 'generated-product';
}

final class _CurrencyRepo implements CurrencyRepository {
  _CurrencyRepo(this.currency);

  final CurrencyCode currency;

  @override
  Future<Result<CurrencyCode?>> getByCode(String code) async =>
      Success(code == currency.code ? currency : null);

  @override
  Future<Result<List<CurrencyCode>>> getAll({bool onlyActive = false}) async =>
      Success([currency]);

  @override
  Future<Result<void>> save(CurrencyCode currency,
          {bool isPredefined = false}) async =>
      const Success(null);

  @override
  Future<Result<void>> toggleActiveStatus(String code, bool isActive) async =>
      const Success(null);

  @override
  Future<Result<String>> getBaseCurrencyCode() async => Success(currency.code);

  @override
  Future<Result<void>> setBaseCurrencyCode(String code) async =>
      const Success(null);
}

final class _GovernanceRepo implements GovernanceRepository {
  _GovernanceRepo(this.status);

  final GovernanceStatus status;

  @override
  Future<Result<GovernanceStatus>> getStatus(
          {bool forceRefresh = false}) async =>
      Success(status);

  @override
  Future<Result<void>> submitActivation(
          SubmitActivationRequest request) async =>
      const Success(null);
}

final class _ProductRepo implements PosProductRepository {
  final List<PosProduct> products = [];

  @override
  Future<Result<PosProduct>> getById(String id) async {
    final matches = products.where((product) => product.id == id);
    if (matches.isEmpty) throw StateError('not needed by this test');
    return Success(matches.first);
  }

  @override
  Future<Result<PosProduct?>> getByBarcode(PosBarcode barcode) async {
    for (final product in products) {
      if (product.barcodes.contains(barcode)) return Success(product);
    }
    return const Success(null);
  }

  @override
  Future<Result<List<PosProduct>>> list({
    bool activeOnly = true,
    String? search,
  }) async {
    final query = search?.trim().toLowerCase();
    return Success(
      products.where((product) {
        if (activeOnly && !product.isActive) return false;
        if (query == null || query.isEmpty) return true;
        return product.name.toLowerCase().contains(query) ||
            product.sku.toLowerCase().contains(query);
      }).toList(growable: false),
    );
  }

  @override
  Future<Result<void>> save(PosProduct product) async {
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      products.add(product);
    } else {
      products[index] = product;
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deactivate(String id) async {
    final index = products.indexWhere((item) => item.id == id);
    if (index != -1) products[index] = products[index].deactivate();
    return const Success(null);
  }
}

PosProduct _product(CurrencyCode currency, String id, String name) {
  return PosProduct.create(
    id: id,
    sku: 'SKU-$id',
    name: name,
    currency: currency,
    salePrice: Money.fromMinorUnits(100, currency),
    purchasePrice: Money.fromMinorUnits(50, currency),
    reorderLevel: PosQuantity.whole(1),
    now: DateTime.utc(2026, 1, 1),
  );
}

PosCatalogCubit _cubit(
  _ProductRepo repository, {
  GovernanceStatus status = GovernanceStatus.activated,
}) {
  final guard = GovernanceWriteGuard(
    CheckGovernanceStatusUseCase(_GovernanceRepo(status)),
  );
  final currency = CurrencyCode(
    code: 'SAR',
    nameAr: 'ريال',
    symbol: 'ر.س',
  );
  return PosCatalogCubit(
    listUseCase: ListPosProductsUseCase(repository),
    saveUseCase: SavePosProductUseCase(repository, guard),
    createUseCase: CreatePosProductUseCase(
      repository,
      _CurrencyRepo(currency),
      guard,
      _IdGenerator(),
    ),
    deactivateUseCase: DeactivatePosProductUseCase(repository, guard),
  );
}

void main() {
  final currency = CurrencyCode(
    code: 'SAR',
    nameAr: 'ريال',
    symbol: 'ر.س',
  );

  group('PosCatalogCubit', () {
    test('loads and searches active products', () async {
      final repository = _ProductRepo()
        ..products.addAll(<PosProduct>[
          _product(currency, '1', 'Coffee'),
          _product(currency, '2', 'Tea'),
        ]);
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.load(search: 'Tea');

      expect(cubit.state.status, PosCatalogStatus.ready);
      expect(cubit.state.products, hasLength(1));
      expect(cubit.state.products.single.name, 'Tea');
    });

    test('saves a product and reloads the catalog', () async {
      final repository = _ProductRepo();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.save(_product(currency, '1', 'Coffee'));

      expect(cubit.state.status, PosCatalogStatus.ready);
      expect(cubit.state.products.single.name, 'Coffee');
    });

    test('deactivates a product and removes it from active listing', () async {
      final repository = _ProductRepo()
        ..products.add(_product(currency, '1', 'Coffee'));
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.deactivate('1');

      expect(cubit.state.status, PosCatalogStatus.ready);
      expect(cubit.state.products, isEmpty);
      expect(repository.products.single.isActive, isFalse);
    });

    test('governance suspension blocks catalog writes', () async {
      final repository = _ProductRepo();
      final cubit = _cubit(
        repository,
        status: const GovernanceStatus(kind: GovernanceStatusKind.suspended),
      );
      addTearDown(cubit.close);

      await cubit.save(_product(currency, '1', 'Coffee'));

      expect(cubit.state.status, PosCatalogStatus.failure);
      expect(repository.products, isEmpty);
    });
  });
}
