import 'package:qayd/domain/exceptions/immutable_entity_exception.dart';
import 'package:qayd/domain/exceptions/invalid_amount_exception.dart';
import 'package:qayd/domain/exceptions/invalid_voucher_transition_exception.dart';
import 'package:qayd/domain/exceptions/self_canceling_entry_exception.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/attachment_ref.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Receipt or payment document with strict draft → confirmed → settled lifecycle.
final class Voucher {
  const Voucher._({
    required this.id,
    required this.type,
    required this.referenceNumber,
    required this.date,
    required this.amount,
    required this.currency,
    required this.counterpartyId,
    required this.affectedAccountId,
    required this.state,
    required this.description,
    required this.attachmentRefs,
    required this.notes,
    required this.tags,
    required this.createdAt,
    required this.confirmedAt,
    required this.settledAt,
  });

  final VoucherId id;
  final VoucherType type;
  final String? referenceNumber;
  final DateTime date;
  final Money amount;
  final CurrencyCode currency;
  final AccountId counterpartyId;
  final AccountId affectedAccountId;
  final VoucherState state;
  final String? description;
  final List<AttachmentRef> attachmentRefs;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? settledAt;

  /// Rehydrates a voucher from persistence (data layer); not for new business creates.
  factory Voucher.restore({
    required VoucherId id,
    required VoucherType type,
    String? referenceNumber,
    required DateTime date,
    required Money amount,
    required CurrencyCode currency,
    required AccountId counterpartyId,
    required AccountId affectedAccountId,
    required VoucherState state,
    String? description,
    List<AttachmentRef> attachmentRefs = const [],
    String? notes,
    List<String> tags = const [],
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? settledAt,
  }) {
    return Voucher._(
      id: id,
      type: type,
      referenceNumber: referenceNumber,
      date: date,
      amount: amount,
      currency: currency,
      counterpartyId: counterpartyId,
      affectedAccountId: affectedAccountId,
      state: state,
      description: description,
      attachmentRefs: List.unmodifiable(attachmentRefs),
      notes: notes,
      tags: List.unmodifiable(tags),
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      settledAt: settledAt,
    );
  }

  factory Voucher.draft({
    required VoucherId id,
    required VoucherType type,
    required DateTime date,
    required Money amount,
    required CurrencyCode currency,
    required AccountId counterpartyId,
    required AccountId affectedAccountId,
    required DateTime createdAt,
    String? referenceNumber,
    String? description,
    List<AttachmentRef> attachmentRefs = const [],
    String? notes,
    List<String> tags = const [],
  }) {
    if (counterpartyId == affectedAccountId) {
      throw const SelfCancelingEntryException(
        messageAr: 'لا يمكن أن يكون الطرف والحساب المتأثر نفس الحساب في السند.',
        code: 'voucher_self_counterparty',
      );
    }
    if (amount.isZero) {
      throw const InvalidAmountException(
        messageAr: 'مبلغ السند يجب أن يكون أكبر من صفر.',
        code: 'voucher_amount_zero',
      );
    }
    return Voucher._(
      id: id,
      type: type,
      referenceNumber: referenceNumber,
      date: date,
      amount: amount,
      currency: currency,
      counterpartyId: counterpartyId,
      affectedAccountId: affectedAccountId,
      state: VoucherState.draft,
      description: description,
      attachmentRefs: List.unmodifiable(attachmentRefs),
      notes: notes,
      tags: List.unmodifiable(tags),
      createdAt: createdAt,
      confirmedAt: null,
      settledAt: null,
    );
  }

  Voucher confirm(DateTime confirmedAt) {
    if (!state.isDraft) {
      throw InvalidVoucherTransitionException(
        messageAr: 'يمكن تأكيد السند من حالة المسودة فقط.',
        from: state,
        to: VoucherState.confirmed,
      );
    }
    return Voucher._(
      id: id,
      type: type,
      referenceNumber: referenceNumber,
      date: date,
      amount: amount,
      currency: currency,
      counterpartyId: counterpartyId,
      affectedAccountId: affectedAccountId,
      state: VoucherState.confirmed,
      description: description,
      attachmentRefs: attachmentRefs,
      notes: notes,
      tags: tags,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      settledAt: null,
    );
  }

  Voucher settle(DateTime settledAt) {
    if (!state.isConfirmed) {
      throw InvalidVoucherTransitionException(
        messageAr: 'يمكن تسوية السند من حالة التأكيد فقط.',
        from: state,
        to: VoucherState.settled,
      );
    }
    return Voucher._(
      id: id,
      type: type,
      referenceNumber: referenceNumber,
      date: date,
      amount: amount,
      currency: currency,
      counterpartyId: counterpartyId,
      affectedAccountId: affectedAccountId,
      state: VoucherState.settled,
      description: description,
      attachmentRefs: attachmentRefs,
      notes: notes,
      tags: tags,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      settledAt: settledAt,
    );
  }

  /// Draft-only edits; confirmed/settled vouchers reject any mutation.
  Voucher updateDraft({
    VoucherType? type,
    String? referenceNumber,
    DateTime? date,
    Money? amount,
    CurrencyCode? currency,
    AccountId? counterpartyId,
    AccountId? affectedAccountId,
    String? description,
    List<AttachmentRef>? attachmentRefs,
    String? notes,
    List<String>? tags,
  }) {
    if (!state.isDraft) {
      throw const ImmutableEntityException(
        messageAr: 'لا يمكن تعديل سند مؤكد أو مسوّى.',
        code: 'voucher_not_draft',
      );
    }
    final nextType = type ?? this.type;
    final nextDate = date ?? this.date;
    final nextCurrency = currency ?? this.currency;
    
    // If currency changed but amount didn't, we must re-classify the minor units.
    var nextAmount = amount ?? this.amount;
    if (nextCurrency != nextAmount.currency) {
      nextAmount = Money.positiveAmount(nextAmount.minorUnits, nextCurrency);
    }

    final nextCounterparty = counterpartyId ?? this.counterpartyId;
    final nextAffected = affectedAccountId ?? this.affectedAccountId;
    if (nextCounterparty == nextAffected) {
      throw const SelfCancelingEntryException(
        messageAr: 'لا يمكن أن يكون الطرف والحساب المتأثر نفس الحساب في السند.',
        code: 'voucher_self_counterparty',
      );
    }
    if (nextAmount.isZero) {
      throw const InvalidAmountException(
        messageAr: 'مبلغ السند يجب أن يكون أكبر من صفر.',
        code: 'voucher_amount_zero',
      );
    }
    return Voucher._(
      id: id,
      type: nextType,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      date: nextDate,
      amount: nextAmount,
      currency: nextCurrency,
      counterpartyId: nextCounterparty,
      affectedAccountId: nextAffected,
      state: state,
      description: description ?? this.description,
      attachmentRefs: List.unmodifiable(attachmentRefs ?? this.attachmentRefs),
      notes: notes ?? this.notes,
      tags: List.unmodifiable(tags ?? this.tags),
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      settledAt: settledAt,
    );
  }

  void assertDraftDeletionAllowed() {
    if (!state.isDraft) {
      throw const ImmutableEntityException(
        messageAr: 'يمكن حذف السندات في حالة المسودة فقط.',
        code: 'voucher_delete_not_draft',
      );
    }
  }

  void assertMutableForAccountingSideEffects() {
    if (state.isSettled) {
      throw const ImmutableEntityException(
        messageAr: 'السند المسوّى غير قابل للتعديل.',
        code: 'voucher_settled_immutable',
      );
    }
  }
}
