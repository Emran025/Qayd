import 'package:qayd/domain/exceptions/invalid_pos_document_transition_exception.dart';

/// Official lifecycle of an immutable POS document.
///
/// Drafts have no stock or ledger side effects. Posted documents are immutable;
/// payment, settlement, return, and cancellation are represented by new linked
/// documents rather than editing the original.
enum PosDocumentStatus {
  draft,
  posted,
  partiallyPaid,
  paid,
  partiallyReturned,
  fullyReturned,
  voided;

  bool get isDraft => this == draft;
  bool get isPosted => this == posted;
  bool get isPaid => this == paid;
  bool get isVoided => this == voided;
  bool get isReturned =>
      this == partiallyReturned || this == fullyReturned;

  bool canTransitionTo(PosDocumentStatus next) {
    if (this == next) return true;

    return switch (this) {
      draft => next == posted || next == voided,
      posted => next == partiallyPaid || next == paid || next == partiallyReturned || next == fullyReturned || next == voided,
      partiallyPaid => next == paid || next == partiallyReturned || next == fullyReturned || next == voided,
      paid => next == partiallyReturned || next == fullyReturned || next == voided,
      partiallyReturned => next == partiallyReturned || next == fullyReturned || next == voided,
      fullyReturned => next == voided,
      voided => false,
    };
  }

  PosDocumentStatus transitionTo(PosDocumentStatus next) {
    if (!canTransitionTo(next)) {
      throw InvalidPosDocumentTransitionException.forbidden(
        from: name,
        to: next.name,
      );
    }
    return next;
  }
}
