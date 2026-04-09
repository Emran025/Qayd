import 'package:qayd/domain/value_objects/governance_status.dart';

class GovernanceUiState {
  const GovernanceUiState({
    this.status = GovernanceStatus.activated,
    this.refreshInFlight = false,
    this.lastErrorAr,
  });

  final GovernanceStatus status;
  final bool refreshInFlight;
  final String? lastErrorAr;

  bool get requiresActivationScreen =>
      status.kind == GovernanceStatusKind.revoked;

  bool get isLocked => status.kind == GovernanceStatusKind.expired;

  bool get showSuspendedBanner => status.kind == GovernanceStatusKind.suspended;

  String? get ownerAccountNumber => status.ownerAccountNumber;
  String? get statusMessage => status.messageAr;
  DateTime? get expiryDate => status.expiryDate;

  GovernanceUiState copyWith({
    GovernanceStatus? status,
    bool? refreshInFlight,
    String? lastErrorAr,
    bool clearLastError = false,
  }) {
    return GovernanceUiState(
      status: status ?? this.status,
      refreshInFlight: refreshInFlight ?? this.refreshInFlight,
      lastErrorAr: clearLastError ? null : (lastErrorAr ?? this.lastErrorAr),
    );
  }
}
