import 'package:flutter/foundation.dart';
import 'package:qayd/domain/value_objects/attachment_ref.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/collateral_status.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// A collateral (رهن / ضمان) held as guarantee against a debt.
///
/// Linked one-to-one with a payment voucher or tripartite transfer.
/// Contains valuation, expiry tracking, and optional image references
/// (separate from voucher attachments) for documenting the collateral's
/// physical state.
///
/// All sensitive data (description, valuation) is encrypted locally and
/// travels inside E2EE payloads — the server never sees this data.
@immutable
final class Collateral {
  const Collateral({
    required this.id,
    required this.voucherId,
    required this.description,
    required this.estimatedValue,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.imageRefs = const [],
    this.encryptedMetadata,
  });

  /// Unique collateral identifier.
  final CollateralId id;

  /// The payment voucher this collateral secures.
  final VoucherId voucherId;

  /// Detailed text describing the collateral item.
  final String description;

  /// Current estimated value of the collateral.
  final Money estimatedValue;

  /// Currency of the valuation.
  final CurrencyCode currency;

  /// Lifecycle status (active → expired → liquidated / released).
  final CollateralStatus status;

  /// When this collateral record was created.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// The date by which the debt must be settled (تاريخ الاستحقاق).
  final DateTime? expiryDate;

  /// Separate images documenting the collateral's physical state.
  final List<AttachmentRef> imageRefs;

  /// Additional encrypted metadata (for future extensibility).
  final String? encryptedMetadata;

  // ── Computed Properties ─────────────────────────────────────────────────

  /// Whether the deadline has passed.
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// Whether the collateral is in an active state.
  bool get isActive => status.isActive;

  /// Whether this collateral is eligible for the liquidation workflow.
  bool get canLiquidate =>
      (status.isActive || status.isExpired) && isExpired;

  /// Whether the status is terminal (no further transitions).
  bool get isTerminal => status.isTerminal;

  // ── State Transitions ───────────────────────────────────────────────────

  /// Marks the collateral as expired (called by expiry checker).
  Collateral markExpired() {
    assert(status.isActive, 'Can only expire active collateral');
    return Collateral(
      id: id,
      voucherId: voucherId,
      description: description,
      estimatedValue: estimatedValue,
      currency: currency,
      status: CollateralStatus.expired,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiryDate: expiryDate,
      imageRefs: imageRefs,
      encryptedMetadata: encryptedMetadata,
    );
  }

  /// Marks the collateral as liquidated after settlement entries are generated.
  Collateral markLiquidated() {
    return Collateral(
      id: id,
      voucherId: voucherId,
      description: description,
      estimatedValue: estimatedValue,
      currency: currency,
      status: CollateralStatus.liquidated,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiryDate: expiryDate,
      imageRefs: imageRefs,
      encryptedMetadata: encryptedMetadata,
    );
  }

  /// Marks the collateral as released (debt paid normally, collateral returned).
  Collateral markReleased() {
    assert(!status.isTerminal, 'Cannot release terminal collateral');
    return Collateral(
      id: id,
      voucherId: voucherId,
      description: description,
      estimatedValue: estimatedValue,
      currency: currency,
      status: CollateralStatus.released,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiryDate: expiryDate,
      imageRefs: imageRefs,
      encryptedMetadata: encryptedMetadata,
    );
  }

  /// Creates a re-evaluated copy with a new value and/or expiry date.
  Collateral revaluate({
    Money? newValue,
    DateTime? newExpiryDate,
  }) {
    assert(!status.isTerminal, 'Cannot revaluate terminal collateral');
    return Collateral(
      id: id,
      voucherId: voucherId,
      description: description,
      estimatedValue: newValue ?? estimatedValue,
      currency: currency,
      status: status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiryDate: newExpiryDate ?? expiryDate,
      imageRefs: imageRefs,
      encryptedMetadata: encryptedMetadata,
    );
  }
}
