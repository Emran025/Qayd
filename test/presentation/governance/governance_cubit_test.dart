import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/governance/dtos/check_governance_status_input.dart';
import 'package:qayd/application/governance/submit_activation_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/governance/governance_ui_state.dart';

class MockCheckGovernanceStatusUseCase extends Mock
    implements CheckGovernanceStatusUseCase {}

class MockSubmitActivationUseCase extends Mock
    implements SubmitActivationUseCase {}

void main() {
  late MockCheckGovernanceStatusUseCase mockCheckGovernance;
  late MockSubmitActivationUseCase mockSubmitActivation;

  setUpAll(() {
    registerFallbackValue(const CheckGovernanceStatusInput());
  });

  setUp(() {
    mockCheckGovernance = MockCheckGovernanceStatusUseCase();
    mockSubmitActivation = MockSubmitActivationUseCase();
  });

  group('GovernanceCubit', () {
    blocTest<GovernanceCubit, GovernanceUiState>(
      'emits correct state when status is expired (locked)',
      build: () {
        when(() => mockCheckGovernance(any())).thenAnswer(
          (_) async => const Success(GovernanceStatus(
            kind: GovernanceStatusKind.expired,
            ownerAccountNumber: '777123',
            messageAr: 'انتهت الفترة التجريبية',
          )),
        );
        return GovernanceCubit(mockCheckGovernance, mockSubmitActivation);
      },
      act: (cubit) => cubit.verifyRemoteStatus(),
      expect: () => [
        isA<GovernanceUiState>().having((p) => p.refreshInFlight, 'busy', true),
        isA<GovernanceUiState>()
            .having((p) => p.refreshInFlight, 'busy', false)
            .having((p) => p.isLocked, 'isLocked', true)
            .having((p) => p.ownerAccountNumber, 'accountNumber', '777123')
            .having(
                (p) => p.statusMessage, 'message', 'انتهت الفترة التجريبية'),
      ],
    );

    test('GovernanceUiState mapping logic', () {
      const lockedState = GovernanceUiState(
        status: GovernanceStatus(kind: GovernanceStatusKind.expired),
      );
      expect(lockedState.isLocked, true);
      expect(lockedState.requiresActivationScreen, false);

      const revokedState = GovernanceUiState(
        status: GovernanceStatus(kind: GovernanceStatusKind.revoked),
      );
      expect(revokedState.isLocked, false);
      expect(revokedState.requiresActivationScreen, true);
    });
  });
}
