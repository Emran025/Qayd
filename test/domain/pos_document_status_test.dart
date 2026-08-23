import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/exceptions/invalid_pos_document_transition_exception.dart';
import 'package:qayd/domain/value_objects/pos_document_status.dart';

void main() {
  group('PosDocumentStatus', () {
    test('draft can be posted or voided only', () {
      expect(
        PosDocumentStatus.draft.transitionTo(PosDocumentStatus.posted),
        PosDocumentStatus.posted,
      );
      expect(
        PosDocumentStatus.draft.transitionTo(PosDocumentStatus.voided),
        PosDocumentStatus.voided,
      );
      expect(
        () => PosDocumentStatus.draft.transitionTo(
          PosDocumentStatus.partiallyPaid,
        ),
        throwsA(isA<InvalidPosDocumentTransitionException>()),
      );
    });

    test('posted can become unpaid, partially paid, paid, returned, or voided', () {
      expect(
        PosDocumentStatus.posted.transitionTo(
          PosDocumentStatus.partiallyPaid,
        ),
        PosDocumentStatus.partiallyPaid,
      );
      expect(
        PosDocumentStatus.posted.transitionTo(PosDocumentStatus.paid),
        PosDocumentStatus.paid,
      );
      expect(
        PosDocumentStatus.posted.transitionTo(
          PosDocumentStatus.partiallyReturned,
        ),
        PosDocumentStatus.partiallyReturned,
      );
      expect(
        PosDocumentStatus.posted.transitionTo(PosDocumentStatus.fullyReturned),
        PosDocumentStatus.fullyReturned,
      );
    });

    test('paid can transition to a return but not back to draft', () {
      expect(
        PosDocumentStatus.paid.transitionTo(
          PosDocumentStatus.partiallyReturned,
        ),
        PosDocumentStatus.partiallyReturned,
      );
      expect(
        () => PosDocumentStatus.paid.transitionTo(PosDocumentStatus.draft),
        throwsA(isA<InvalidPosDocumentTransitionException>()),
      );
    });

    test('fully returned is terminal except for voiding metadata', () {
      expect(
        PosDocumentStatus.fullyReturned.transitionTo(
          PosDocumentStatus.voided,
        ),
        PosDocumentStatus.voided,
      );
      expect(
        () => PosDocumentStatus.fullyReturned.transitionTo(
          PosDocumentStatus.paid,
        ),
        throwsA(isA<InvalidPosDocumentTransitionException>()),
      );
    });

    test('voided cannot transition to any other state', () {
      expect(
        () => PosDocumentStatus.voided.transitionTo(PosDocumentStatus.posted),
        throwsA(isA<InvalidPosDocumentTransitionException>()),
      );
    });

    test('same-state transition is idempotent', () {
      expect(
        PosDocumentStatus.posted.transitionTo(PosDocumentStatus.posted),
        PosDocumentStatus.posted,
      );
    });

    test('status helpers expose official lifecycle semantics', () {
      expect(PosDocumentStatus.draft.isDraft, isTrue);
      expect(PosDocumentStatus.posted.isPosted, isTrue);
      expect(PosDocumentStatus.paid.isPaid, isTrue);
      expect(PosDocumentStatus.partiallyReturned.isReturned, isTrue);
      expect(PosDocumentStatus.fullyReturned.isReturned, isTrue);
      expect(PosDocumentStatus.voided.isVoided, isTrue);
    });
  });
}
