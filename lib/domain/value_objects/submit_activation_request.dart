/// Credentials bundle sent to the governance backend when (re)activating.
final class SubmitActivationRequest {
  const SubmitActivationRequest({
    required this.organizationId,
    required this.licenseKey,
  });

  final String organizationId;
  final String licenseKey;
}
