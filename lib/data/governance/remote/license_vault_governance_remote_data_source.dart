import 'package:qayd/data/governance/remote/governance_remote_data_source.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/value_objects/governance_status.dart';
import 'package:qayd/domain/value_objects/submit_activation_request.dart';

/// Production [GovernanceRemoteDataSource] that derives governance status
/// directly from the [LicenseVault] (populated by the Auth API on login).
///
/// This bridges [SecurityCubit]'s license resolution with [GovernanceCubit]'s
/// write-guard, ensuring both use the same authoritative data source without
/// a redundant network call.
final class LicenseVaultGovernanceRemoteDataSource
    implements GovernanceRemoteDataSource {
  LicenseVaultGovernanceRemoteDataSource({required LicenseVault licenseVault})
      : _vault = licenseVault;

  final LicenseVault _vault;

  @override
  Future<GovernanceStatus> fetchStatus() async {
    final data = await _vault.readLicenseData();

    if (data == null) {
      // Not yet provisioned → treat as activated so writes aren't blocked
      // during the trial onboarding flow (SecurityCubit handles the gate).
      return GovernanceStatus.activated;
    }

    final status = data['status'] as String? ?? '';
    final hasFormalLicense = data['has_formal_license'] as bool? ?? false;
    final accountClosed = data['account_closed'] as bool? ?? false;
    final isActive = data['is_active'] as bool? ?? true;

    // Map to GovernanceStatus so GovernanceWriteGuard blocks writes correctly.
    if (status == 'FORCE_REVOKE' || status == 'revoked' || !isActive) {
      return GovernanceStatus(
        kind: GovernanceStatusKind.revoked,
        messageAr: 'تم إلغاء تفعيل الحساب من قِبل الإدارة.',
      );
    }
    if (accountClosed) {
      return GovernanceStatus(
        kind: GovernanceStatusKind.expired,
        messageAr: 'انتهت فترة التجربة المجانية. يرجى التواصل مع الإدارة لتجديد الاشتراك.',
      );
    }
    if (status == 'suspended') {
      return GovernanceStatus(
        kind: GovernanceStatusKind.suspended,
        messageAr: 'الحساب موقوف مؤقتاً.',
      );
    }
    if (hasFormalLicense || status == 'active') {
      return GovernanceStatus.activated;
    }

    // Trial period — allow writes.
    return GovernanceStatus.activated;
  }

  /// Governance activation (org-id / license-key flow) is not used in the
  /// LicenseVault path; writes are allowed via SecurityCubit provisioning.
  @override
  Future<void> submitActivation(SubmitActivationRequest request) async {
    // No-op: activation is handled by SecurityCubit.provisionDevice().
  }
}
