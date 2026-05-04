import 'package:qayd/presentation/l10n/app_strings.dart';
/// Represents the sync privacy policy modes.
///
/// Controls who can discover the user's public key and sync vouchers with them:
///   - [open]: anyone can sync (default, backward-compatible).
///   - [openWithBlocklist]: everyone EXCEPT users in the block list.
///   - [closedWithAllowlist]: ONLY users in the allow list.
///   - [openToContacts]: only users in my contacts/accounts can sync.
///   - [closed]: nobody can sync.
enum SyncPolicyMode {
  open,
  openWithBlocklist,
  closedWithAllowlist,
  openToContacts,
  closed;

  /// Parses the server's snake_case string into the enum value.
  static SyncPolicyMode fromString(String value) {
    return switch (value) {
      'open' => SyncPolicyMode.open,
      'open_with_blocklist' => SyncPolicyMode.openWithBlocklist,
      'closed_with_allowlist' => SyncPolicyMode.closedWithAllowlist,
      'open_to_contacts' => SyncPolicyMode.openToContacts,
      'closed' => SyncPolicyMode.closed,
      _ => SyncPolicyMode.open,
    };
  }

  /// Converts to the server's snake_case string.
  String toApiString() {
    return switch (this) {
      SyncPolicyMode.open => 'open',
      SyncPolicyMode.openWithBlocklist => 'open_with_blocklist',
      SyncPolicyMode.closedWithAllowlist => 'closed_with_allowlist',
      SyncPolicyMode.openToContacts => 'open_to_contacts',
      SyncPolicyMode.closed => 'closed',
    };
  }

  /// Arabic display name for settings UI.
  String get displayNameAr {
    return switch (this) {
      SyncPolicyMode.open => AppStrings.openToEveryone,
      SyncPolicyMode.openWithBlocklist => AppStrings.openWithBlocklist,
      SyncPolicyMode.closedWithAllowlist => AppStrings.restrictedAllowListOnly,
      SyncPolicyMode.openToContacts => AppStrings.openToMyAccounts,
      SyncPolicyMode.closed => AppStrings.closedToEveryone,
    };
  }

  /// Arabic description for settings UI.
  String get descriptionAr {
    return switch (this) {
      SyncPolicyMode.open =>
        AppStrings.itAllowsAnyoneWith,
      SyncPolicyMode.openWithBlocklist =>
        AppStrings.allowsEveryoneExceptUsers,
      SyncPolicyMode.closedWithAllowlist =>
        AppStrings.onlyUsersSpecifiedIn,
      SyncPolicyMode.openToContacts =>
        AppStrings.onlyPeopleOnYour,
      SyncPolicyMode.closed =>
        AppStrings.itPreventsEveryoneFrom,
    };
  }
}

/// A single entry in the user's sync access list.
class SyncAccessEntry {
  const SyncAccessEntry({
    required this.id,
    this.targetUserId,
    required this.targetName,
    required this.targetPhone,
    this.targetEmail,
    required this.listType,
    this.localAccountId,
  });

  final int id;
  final int? targetUserId;
  final String targetName;
  final String targetPhone;
  final String? targetEmail;
  final String? localAccountId;

  /// 'block' or 'allow'
  final String listType;

  factory SyncAccessEntry.fromJson(Map<String, dynamic> json) {
    final target = json['target_user'] as Map<String, dynamic>;
    return SyncAccessEntry(
      id: json['id'] as int,
      targetUserId: target['id'] as int?,
      targetName: target['name'] as String? ?? '',
      targetPhone: target['phone'] as String? ?? '',
      targetEmail: target['email'] as String?,
      listType: json['list_type'] as String,
    );
  }
}

/// The user's complete sync privacy policy including mode and access list.
class SyncPrivacyPolicy {
  const SyncPrivacyPolicy({
    required this.mode,
    this.accessList = const [],
  });

  final SyncPolicyMode mode;
  final List<SyncAccessEntry> accessList;

  /// Entries filtered to only block entries.
  List<SyncAccessEntry> get blockList =>
      accessList.where((e) => e.listType == 'block').toList();

  /// Entries filtered to only allow entries.
  List<SyncAccessEntry> get allowList =>
      accessList.where((e) => e.listType == 'allow').toList();

  factory SyncPrivacyPolicy.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['access_list'] as List<dynamic>? ?? [];
    final entries = entriesRaw
        .map((e) => SyncAccessEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return SyncPrivacyPolicy(
      mode: SyncPolicyMode.fromString(json['sync_policy'] as String? ?? 'open'),
      accessList: entries,
    );
  }

  SyncPrivacyPolicy copyWith({
    SyncPolicyMode? mode,
    List<SyncAccessEntry>? allowList,
    List<SyncAccessEntry>? blockList,
  }) {
    return SyncPrivacyPolicy(
      mode: mode ?? this.mode,
      accessList: [
        if (allowList != null) ...allowList else ...this.allowList,
        if (blockList != null) ...blockList else ...this.blockList,
      ],
    );
  }
}
