/// Party contact data; at least one reachable field must be present.
final class ContactInfo {
  ContactInfo({this.name, this.phone, this.email}) {
    final hasName = name != null && name!.trim().isNotEmpty;
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    final hasEmail = email != null && email!.trim().isNotEmpty;
    if (!hasName && !hasPhone && !hasEmail) {
      throw ArgumentError(
        'ContactInfo requires at least one of name, phone, or email',
      );
    }
  }

  final String? name;
  final String? phone;
  final String? email;
}
