import 'package:flutter/foundation.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/core/result/result.dart';

/// State for the sync privacy settings UI.
class SyncPrivacyState {
  const SyncPrivacyState({
    this.policy,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.successMessage,
  });

  final SyncPrivacyPolicy? policy;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final String? successMessage;

  SyncPrivacyState copyWith({
    SyncPrivacyPolicy? policy,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SyncPrivacyState(
      policy: policy ?? this.policy,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Manages the sync privacy policy state and operations.
///
/// Uses a simple ChangeNotifier instead of a Cubit to match existing
/// patterns in the settings pages (e.g., notification_settings_cubit.dart).
class SyncPrivacyCubit extends ChangeNotifier {
  SyncPrivacyCubit({
    required IdentityRepository identityRepository,
    required AccountRepository accountRepository,
  })  : _identityRepo = identityRepository,
        _accountRepo = accountRepository;

  final IdentityRepository _identityRepo;
  final AccountRepository _accountRepo;

  SyncPrivacyState _state = const SyncPrivacyState();
  SyncPrivacyState get state => _state;

  void _emit(SyncPrivacyState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Loads the current sync privacy policy from the server.
  Future<void> loadPolicy() async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      var policy = await _identityRepo.getSyncPolicy();
      policy = await _resolveLocalNames(policy);
      _emit(_state.copyWith(policy: policy, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل إعدادات الخصوصية.',
      ));
    }
  }

  Future<SyncPrivacyPolicy> _resolveLocalNames(SyncPrivacyPolicy policy) async {
    final updatedAllow = await _resolveListNames(policy.allowList);
    final updatedBlock = await _resolveListNames(policy.blockList);
    
    return policy.copyWith(
      allowList: updatedAllow,
      blockList: updatedBlock,
    );
  }

  Future<List<SyncAccessEntry>> _resolveListNames(List<SyncAccessEntry> list) async {
    final List<SyncAccessEntry> resolved = [];
    for (final entry in list) {
      String localName = entry.targetName;
      
      if (entry.targetPhone.isNotEmpty) {
        final phoneResult = await _accountRepo.findAccountByPhone(entry.targetPhone);
        final accountId = phoneResult.valueOrNull;
        if (accountId != null) {
          final accountResult = await _accountRepo.getById(accountId);
          final account = accountResult.valueOrNull;
          if (account != null && account.name.isNotEmpty) {
            localName = account.name;
          }
        }
      }
      
      resolved.add(SyncAccessEntry(
        id: entry.id,
        targetUserId: entry.targetUserId,
        targetName: localName,
        targetPhone: entry.targetPhone,
        targetEmail: entry.targetEmail,
        listType: entry.listType,
      ));
    }
    return resolved;
  }

  /// Updates the sync policy mode on the server.
  Future<void> updatePolicyMode(SyncPolicyMode mode) async {
    _emit(_state.copyWith(
        isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await _identityRepo.updateSyncPolicy(mode);
      // Reload the full policy to get updated state.
      var policy = await _identityRepo.getSyncPolicy();
      policy = await _resolveLocalNames(policy);
      _emit(_state.copyWith(
        policy: policy,
        isUpdating: false,
        successMessage: 'تم تحديث سياسة الخصوصية.',
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: e.message,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: 'تعذّر تحديث سياسة الخصوصية.',
      ));
    }
  }

  /// Synchronizes the access list with a set of selected accounts.
  ///
  /// This calculates the difference between current entries and selected accounts,
  /// performing necessary additions and removals.
  Future<void> syncListWithAccounts({
    required List<AccountSummaryDto> selectedAccounts,
    required String listType,
  }) async {
    final policy = _state.policy;
    if (policy == null) return;

    _emit(_state.copyWith(
        isUpdating: true, clearError: true, clearSuccess: true));

    try {
      final currentEntries =
          listType == 'block' ? policy.blockList : policy.allowList;

      // 1. Map existing entries by phone (cleaned) for comparison
      final Map<String, int> phoneToEntryId = {};
      for (final e in currentEntries) {
        if (e.targetPhone.isNotEmpty) {
          final cleaned = e.targetPhone.replaceAll(RegExp(r'\s+'), '');
          phoneToEntryId[cleaned] = e.id;
        }
      }

      // 2. Extract phones from selected accounts (cleaned)
      final Set<String> selectedPhones = {};
      for (final acc in selectedAccounts) {
        final partyResult =
            await _accountRepo.getPartyDetails(AccountId(acc.id));
        final party = partyResult.valueOrNull;
        final phone = (party?.phoneNumber?.trim() ?? 
                       party?.whatsappNumber?.trim() ?? 
                       '')
            .replaceAll(RegExp(r'\s+'), '');
            
        if (phone.isNotEmpty) {
          selectedPhones.add(phone);
        }
      }

      // 3. Determine additions and removals
      final toAdd = selectedPhones.where((p) => !phoneToEntryId.containsKey(p));
      
      final toRemoveIds = <int>[];
      for (final entry in currentEntries) {
        final cleaned = entry.targetPhone.replaceAll(RegExp(r'\s+'), '');
        if (cleaned.isNotEmpty && !selectedPhones.contains(cleaned)) {
          toRemoveIds.add(entry.id);
        }
      }

      // 4. Execute changes
      for (final phone in toAdd) {
        await _identityRepo.addToSyncAccessList(
            phone: phone, listType: listType);
      }
      for (final entryId in toRemoveIds) {
        await _identityRepo.removeFromSyncAccessList(entryId: entryId);
      }

      // 5. Reload fresh state
      var freshPolicy = await _identityRepo.getSyncPolicy();
      freshPolicy = await _resolveLocalNames(freshPolicy);
      _emit(_state.copyWith(
        policy: freshPolicy,
        isUpdating: false,
        successMessage: 'تم تحديث القائمة بنجاح.',
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(isUpdating: false, error: e.message));
    } catch (e) {
      _emit(_state.copyWith(isUpdating: false, error: 'تعذّر تحديث القائمة.'));
    }
  }

  /// Adds a user to the access list by phone number.
  Future<void> addToList({
    required String phone,
    required String listType,
  }) async {
    _emit(_state.copyWith(
        isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await _identityRepo.addToSyncAccessList(
        phone: phone,
        listType: listType,
      );
      // Reload to get fresh list.
      var policy = await _identityRepo.getSyncPolicy();
      policy = await _resolveLocalNames(policy);
      _emit(_state.copyWith(
        policy: policy,
        isUpdating: false,
        successMessage: 'تم إضافة المستخدم للقائمة.',
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: e.message,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: 'تعذّر إضافة المستخدم للقائمة.',
      ));
    }
  }

  /// Removes an entry from the access list.
  Future<void> removeEntry(int entryId) async {
    _emit(_state.copyWith(
        isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await _identityRepo.removeFromSyncAccessList(entryId: entryId);
      // Reload to get fresh list.
      var policy = await _identityRepo.getSyncPolicy();
      policy = await _resolveLocalNames(policy);
      _emit(_state.copyWith(
        policy: policy,
        isUpdating: false,
        successMessage: 'تم حذف المستخدم من القائمة.',
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: e.message,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: 'تعذّر حذف المستخدم من القائمة.',
      ));
    }
  }

  /// Clears any transient messages.
  void clearMessages() {
    _emit(_state.copyWith(clearError: true, clearSuccess: true));
  }
}
