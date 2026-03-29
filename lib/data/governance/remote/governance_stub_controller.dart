import 'package:qayd/domain/value_objects/governance_status.dart';

/// Mutable knobs for the stub remote source (dev / integration tests).
/// Replace with real API responses when wiring production.
final class GovernanceStubController {
  GovernanceStubController({
    this.remoteStatus = GovernanceStatus.activated,
  });

  /// Simulated server-side status returned by [fetchStatus].
  GovernanceStatus remoteStatus;

  /// When true, next [submitActivation] call throws (simulates invalid credentials).
  bool rejectNextActivation = false;
}
