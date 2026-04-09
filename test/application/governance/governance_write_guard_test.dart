import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/governance/dtos/check_governance_status_input.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';

class MockCheckGovernanceStatusUseCase extends Mock
    implements CheckGovernanceStatusUseCase {}

void main() {
  late MockCheckGovernanceStatusUseCase mockCheckGovernance;
  late GovernanceWriteGuard guard;

  setUpAll(() {
    registerFallbackValue(const CheckGovernanceStatusInput());
  });

  setUp(() {
    mockCheckGovernance = MockCheckGovernanceStatusUseCase();
    guard = GovernanceWriteGuard(mockCheckGovernance);
  });

  group('GovernanceWriteGuard', () {
    test('should permit writes when status is activated', () async {
      // arrange
      when(() => mockCheckGovernance(any())).thenAnswer(
        (_) async => const Success(
            GovernanceStatus(kind: GovernanceStatusKind.activated)),
      );

      // act
      final result = await guard.assertWritesPermitted();

      // assert
      expect(result.isSuccess, true);
    });

    test('should block writes when status is suspended', () async {
      // arrange
      const message = 'Service suspended';
      when(() => mockCheckGovernance(any())).thenAnswer(
        (_) async => const Success(GovernanceStatus(
          kind: GovernanceStatusKind.suspended,
          messageAr: message,
        )),
      );

      // act
      final result = await guard.assertWritesPermitted();

      // assert
      expect(result.isFailure, true);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect((f as ValidationFailure).code, 'governance_suspended');
          expect(f.messageAr, message);
        },
        (_) => fail('Should have failed'),
      );
    });

    test('should block writes when status is expired', () async {
      // arrange
      when(() => mockCheckGovernance(any())).thenAnswer(
        (_) async =>
            const Success(GovernanceStatus(kind: GovernanceStatusKind.expired)),
      );

      // act
      final result = await guard.assertWritesPermitted();

      // assert
      expect(result.isFailure, true);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect((f as ValidationFailure).code, 'governance_expired');
        },
        (_) => fail('Should have failed'),
      );
    });

    test('should block writes when status is revoked', () async {
      // arrange
      when(() => mockCheckGovernance(any())).thenAnswer(
        (_) async =>
            const Success(GovernanceStatus(kind: GovernanceStatusKind.revoked)),
      );

      // act
      final result = await guard.assertWritesPermitted();

      // assert
      expect(result.isFailure, true);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect((f as ValidationFailure).code, 'governance_revoked');
        },
        (_) => fail('Should have failed'),
      );
    });
  });
}
