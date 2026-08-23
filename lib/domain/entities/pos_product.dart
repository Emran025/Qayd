import 'dart:collection';

import 'package:qayd/domain/exceptions/invalid_pos_product_exception.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_barcode.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';

/// Product aggregate used by POS catalog and inventory flows.
final class PosProduct {
  PosProduct._({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.unitName,
    required this.currency,
    required this.salePrice,
    required this.purchasePrice,
    required this.quantityScale,
    required this.reorderLevel,
    required this.expiryTracking,
    required this.isActive,
    required List<PosBarcode> barcodes,
    required this.createdAt,
    required this.updatedAt,
  }) : barcodes = UnmodifiableListView(barcodes);

  factory PosProduct.create({
    required String id,
    required String sku,
    required String name,
    required CurrencyCode currency,
    required Money salePrice,
    required Money purchasePrice,
    int quantityScale = 0,
    PosQuantity? reorderLevel,
    bool expiryTracking = false,
    List<PosBarcode> barcodes = const <PosBarcode>[],
    String? description,
    String unitName = 'unit',
    DateTime? now,
  }) {
    final trimmedId = id.trim();
    final trimmedSku = sku.trim();
    final trimmedName = name.trim();
    final trimmedUnit = unitName.trim();
    if (trimmedId.isEmpty) throw InvalidPosProductException.idRequired();
    if (trimmedSku.isEmpty) throw InvalidPosProductException.skuRequired();
    if (trimmedName.isEmpty) throw InvalidPosProductException.nameRequired();
    if (trimmedUnit.isEmpty) throw InvalidPosProductException.unitRequired();
    if (salePrice.currency != currency || purchasePrice.currency != currency) {
      throw InvalidPosProductException.currencyMismatch();
    }
    if (salePrice.isNegative || purchasePrice.isNegative) {
      throw InvalidPosProductException.priceNegative();
    }
    if (quantityScale < PosQuantity.minScale ||
        quantityScale > PosQuantity.maxScale) {
      throw InvalidPosProductException.quantityScaleInvalid();
    }
    final threshold = reorderLevel ?? PosQuantity.fromScaled(
      0,
      scale: quantityScale,
    );
    if (threshold.scale != quantityScale) {
      throw InvalidPosProductException.thresholdScaleMismatch();
    }
    final uniqueBarcodes = <String>{};
    for (final barcode in barcodes) {
      if (!uniqueBarcodes.add(barcode.value)) {
        throw InvalidPosProductException.duplicateBarcode();
      }
    }
    final timestamp = (now ?? DateTime.now()).toUtc();
    return PosProduct._(
      id: trimmedId,
      sku: trimmedSku,
      name: trimmedName,
      description: description?.trim(),
      unitName: trimmedUnit,
      currency: currency,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      quantityScale: quantityScale,
      reorderLevel: threshold,
      expiryTracking: expiryTracking,
      isActive: true,
      barcodes: barcodes,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  final String id;
  final String sku;
  final String name;
  final String? description;
  final String unitName;
  final CurrencyCode currency;
  final Money salePrice;
  final Money purchasePrice;
  final int quantityScale;
  final PosQuantity reorderLevel;
  final bool expiryTracking;
  final bool isActive;
  final List<PosBarcode> barcodes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PosBarcode? get primaryBarcode => barcodes.isEmpty ? null : barcodes.first;

  PosProduct addBarcode(PosBarcode barcode) {
    if (barcodes.any((item) => item == barcode)) {
      throw InvalidPosProductException.duplicateBarcode();
    }
    return _copyWith(
      barcodes: [...barcodes, barcode],
      updatedAt: DateTime.now().toUtc(),
    );
  }

  PosProduct deactivate() {
    if (!isActive) return this;
    return _copyWith(isActive: false, updatedAt: DateTime.now().toUtc());
  }

  PosProduct activate() {
    if (isActive) return this;
    return _copyWith(isActive: true, updatedAt: DateTime.now().toUtc());
  }

  PosProduct _copyWith({
    List<PosBarcode>? barcodes,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return PosProduct._(
      id: id,
      sku: sku,
      name: name,
      description: description,
      unitName: unitName,
      currency: currency,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      quantityScale: quantityScale,
      reorderLevel: reorderLevel,
      expiryTracking: expiryTracking,
      isActive: isActive ?? this.isActive,
      barcodes: barcodes ?? this.barcodes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
