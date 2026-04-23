import 'package:qayd/domain/exceptions/account_deletion_exception.dart';
import 'package:qayd/domain/exceptions/invalid_state_transition_exception.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/money.dart';

/// Node in the chart of accounts. Nature and classification are fixed after creation.
class Account {
  const Account._({
    required this.id,
    required this.name,
    required this.nature,
    required this.classification,
    required this.parentId,
    required this.isDefault,
    required this.createdAt,
    required this.isActive,
    required this.isArchived,
    this.metadata = const {},
  });

  final AccountId id;
  final String name;
  final AccountNature nature;
  final AccountClassification classification;
  final AccountId? parentId;
  final bool isDefault;
  final DateTime createdAt;
  final bool isActive;
  final bool isArchived;

  /// Additional extensible data (e.g., asset serials, purchase dates).
  final Map<String, dynamic> metadata;

  bool get isRoot => parentId == null;

  /// Primary account under the implicit root: carries classification and implied nature.
  factory Account.createRoot({
    required AccountId id,
    required String name,
    required AccountClassification classification,
    required DateTime createdAt,
    bool isDefault = false,
    bool isActive = true,
    Map<String, dynamic> metadata = const {},
  }) {
    return Account._(
      id: id,
      name: _requireName(name),
      nature: classification.defaultNature,
      classification: classification,
      parentId: null,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: false,
      metadata: metadata,
    );
  }

  /// Rehydrates an account from persistence (data layer); not for new creates.
  factory Account.restore({
    required AccountId id,
    required String name,
    required AccountNature nature,
    required AccountClassification classification,
    AccountId? parentId,
    required bool isDefault,
    required DateTime createdAt,
    required bool isActive,
    required bool isArchived,
    Map<String, dynamic> metadata = const {},
  }) {
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  /// Sub-account: inherits [nature] and [classification] from [parent].
  factory Account.createChild({
    required AccountId id,
    required String name,
    required Account parent,
    required DateTime createdAt,
    bool isDefault = false,
    bool isActive = true,
    Map<String, dynamic> metadata = const {},
  }) {
    return Account._(
      id: id,
      name: _requireName(name),
      nature: parent.nature,
      classification: parent.classification,
      parentId: parent.id,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: false,
      metadata: metadata,
    );
  }

  static String _requireName(String raw) {
    final n = raw.trim();
    if (n.isEmpty) {
      throw ArgumentError.value(raw, 'name', 'Account name is required');
    }
    return n;
  }

  Account rename(String newName) {
    return Account._(
      id: id,
      name: _requireName(newName),
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  Account move(AccountId? newParentId, AccountNature newNature) {
    return Account._(
      id: id,
      name: name,
      nature: newNature,
      classification: classification,
      parentId: newParentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  Account reclassify(AccountClassification newClassification, AccountNature newNature) {
    return Account._(
      id: id,
      name: name,
      nature: newNature,
      classification: newClassification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  Account updateMetadata(Map<String, dynamic> newMetadata) {
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: isArchived,
      metadata: {...metadata, ...newMetadata},
    );
  }

  Account activate() {
    if (isActive) return this;
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: true,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  /// Deactivate only when [balance] is zero (see accounting domain model).
  Account deactivate({required Money balance}) {
    if (isDefault) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن إيقاف الحساب الافتراضي.',
        code: 'account_deactivate_default',
      );
    }
    if (!balance.isZero) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن إيقاف حساب له رصيد غير صفر.',
        code: 'account_balance_blocks_deactivate',
      );
    }
    if (!isActive) return this;
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: false,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  /// Move under [newParent] only when classification and nature stay aligned.
  Account relocateUnder(Account newParent) {
    if (classification != newParent.classification ||
        nature != newParent.nature) {
      throw const InvalidStateTransitionException(
        messageAr: 'لا يمكن نقل الحساب إلى أصل بتصنيف أو طبيعة مختلفة.',
        code: 'account_reparent_classification_mismatch',
      );
    }
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: newParent.id,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: isArchived,
      metadata: metadata,
    );
  }

  /// Structural delete: zero balance and no children (transaction history is enforced in application layer).
  void assertCanDelete({
    required Money balance,
    required bool hasChildAccounts,
  }) {
    if (isDefault) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن حذف الحساب الافتراضي.',
        code: 'account_delete_default',
      );
    }
    if (!balance.isZero) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن حذف حساب له رصيد غير صفر.',
        code: 'account_delete_balance',
      );
    }
    if (hasChildAccounts) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن حذف حساب يملك حسابات فرعية.',
        code: 'account_delete_children',
      );
    }
  }

  /// Archive an account that has been fully settled (balance == 0).
  Account archive({required Money balance}) {
    if (isDefault) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن أرشفة الحساب الافتراضي.',
        code: 'account_archive_default',
      );
    }
    if (!balance.isZero) {
      throw const AccountDeletionException(
        messageAr: 'لا يمكن أرشفة حساب له رصيد غير صفر. يجب تسوية الحساب أولاً.',
        code: 'account_archive_balance',
      );
    }
    if (isArchived) return this;
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: true,
      metadata: metadata,
    );
  }

  /// Restore a previously archived account back to active status.
  Account unarchive() {
    if (!isArchived) return this;
    return Account._(
      id: id,
      name: name,
      nature: nature,
      classification: classification,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      isActive: isActive,
      isArchived: false,
      metadata: metadata,
    );
  }
}
