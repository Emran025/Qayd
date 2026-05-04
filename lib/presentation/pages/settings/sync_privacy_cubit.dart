import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


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

      // Merge local overrides (for accounts without phones)
      final allAccountsResult = await _accountRepo.getAll();
      final localEntries = <SyncAccessEntry>[];
      if (allAccountsResult.isSuccess) {
        for (final account in allAccountsResult.valueOrNull!) {
          final privacyMode = account.metadata['sync_privacy'] as String?;
          if (privacyMode != null) {
            // Check if this account already has a phone-based entry on server
            // to avoid duplicates if they later added a phone.
            final partyResult = await _accountRepo.getPartyDetails(account.id);
            final phone = partyResult.valueOrNull?.phoneNumber ?? '';

            bool alreadyOnServer = false;
            if (phone.isNotEmpty) {
              final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
              alreadyOnServer = policy.accessList.any((e) =>
                  e.targetPhone.replaceAll(RegExp(r'\s+'), '') == cleaned);
            }

            if (!alreadyOnServer) {
              localEntries.add(SyncAccessEntry(
                id: -1 *
                    int.parse(account.id.value.hashCode
                        .toString()
                        .substring(0, 6)), // Pseudo-id
                targetName: account.name,
                targetPhone: phone,
                listType: privacyMode,
                localAccountId: account.id.value,
              ));
            }
          }
        }
      }

      if (localEntries.isNotEmpty) {
        policy = policy.copyWith(
          allowList: [
            ...policy.allowList,
            ...localEntries.where((e) => e.listType == 'allow')
          ],
          blockList: [
            ...policy.blockList,
            ...localEntries.where((e) => e.listType == 'block')
          ],
        );
      }

      policy = await _resolveLocalNames(policy);
      _emit(_state.copyWith(policy: policy, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        error: AppStrings.unableToLoadPrivacy,
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

  Future<List<SyncAccessEntry>> _resolveListNames(
      List<SyncAccessEntry> list) async {
    final List<SyncAccessEntry> resolved = [];
    for (final entry in list) {
      String localName = entry.targetName;
      String? localId = entry.localAccountId;

      if (entry.targetPhone.isNotEmpty) {
        final phoneResult =
            await _accountRepo.findAccountByPhone(entry.targetPhone);
        final accountId = phoneResult.valueOrNull;
        if (accountId != null) {
          final accountResult = await _accountRepo.getById(accountId);
          final account = accountResult.valueOrNull;
          if (account != null && account.name.isNotEmpty) {
            localName = account.name;
            localId = account.id.value;
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
        localAccountId: localId,
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
        successMessage: AppStrings.privacyPolicyHasBeen,
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: e.message,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: AppStrings.thePrivacyPolicyCould,
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
      int skippedNoPhone = 0;
      for (final acc in selectedAccounts) {
        final partyResult =
            await _accountRepo.getPartyDetails(AccountId(acc.id));
        final party = partyResult.valueOrNull;
        final phone =
            (party?.phoneNumber?.trim() ?? party?.whatsappNumber?.trim() ?? '')
                .replaceAll(RegExp(r'\s+'), '');

        if (phone.isNotEmpty) {
          selectedPhones.add(phone);
        } else {
          skippedNoPhone++;
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
        if (entryId > 0) {
          await _identityRepo.removeFromSyncAccessList(entryId: entryId);
        }
      }

      // 4.1 Handle local-only overrides for phone-less accounts
      for (final acc in selectedAccounts) {
        final partyResult =
            await _accountRepo.getPartyDetails(AccountId(acc.id));
        final phone = partyResult.valueOrNull?.phoneNumber ?? '';
        if (phone.isEmpty) {
          final accountResult = await _accountRepo.getById(AccountId(acc.id));
          if (accountResult.isSuccess) {
            final account = accountResult.valueOrNull!;
            await _accountRepo
                .save(account.updateMetadata({'sync_privacy': listType}));
          }
        }
      }

      // 4.2 Clear local-only overrides for accounts UNSELECTED in this listType
      final allAccountsResult = await _accountRepo.getAll();
      final selectedIds = selectedAccounts.map((e) => e.id).toSet();
      if (allAccountsResult.isSuccess) {
        for (final account in allAccountsResult.valueOrNull!) {
          if (account.metadata['sync_privacy'] == listType &&
              !selectedIds.contains(account.id.value)) {
            await _accountRepo
                .save(account.updateMetadata({'sync_privacy': null}));
          }
        }
      }

      // 5. Reload fresh state
      var freshPolicy = await _identityRepo.getSyncPolicy();
      freshPolicy = await _resolveLocalNames(freshPolicy);

      String successMsg = AppStrings.theListHasBeen;
      if (skippedNoPhone > 0) {
        successMsg += ' (تم تخطي $skippedNoPhone حساب لعدم وجود رقم هاتف)';
      }

      _emit(_state.copyWith(
        policy: freshPolicy,
        isUpdating: false,
        successMessage: successMsg,
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(isUpdating: false, error: e.message));
    } on DioException catch (e) {
      String errorMsg = AppStrings.couldNotUpdateThe;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.toString().contains('SocketException')) {
        errorMsg = AppStrings.internetConnectionFailedPlease;
      }
      _emit(_state.copyWith(isUpdating: false, error: errorMsg));
    } catch (e) {
      String errorMsg = AppStrings.couldNotUpdateThe;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        errorMsg = AppStrings.internetConnectionFailedPlease;
      }
      _emit(_state.copyWith(isUpdating: false, error: errorMsg));
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
        successMessage: AppStrings.theUserHasBeen,
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: e.message,
      ));
    } on DioException catch (e) {
      String errorMsg = AppStrings.theUserCouldNot;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.toString().contains('SocketException')) {
        errorMsg = AppStrings.internetConnectionFailedPlease;
      }
      _emit(_state.copyWith(
        isUpdating: false,
        error: errorMsg,
      ));
    } catch (e) {
      String errorMsg = AppStrings.theUserCouldNot;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        errorMsg = AppStrings.internetConnectionFailedPlease;
      }
      _emit(_state.copyWith(
        isUpdating: false,
        error: errorMsg,
      ));
    }
  }

  /// Removes an entry from the access list.
  Future<void> removeEntry(int entryId) async {
    _emit(_state.copyWith(
        isUpdating: true, clearError: true, clearSuccess: true));
    try {
      if (entryId > 0) {
        await _identityRepo.removeFromSyncAccessList(entryId: entryId);
      } else {
        // Local-only removal
        // Find account with this pseudo-id/metadata and clear it.
        final accountsResult = await _accountRepo.getAll();
        if (accountsResult.isSuccess) {
          for (final account in accountsResult.valueOrNull!) {
            final pseudoId = -1 *
                int.parse(account.id.value.hashCode.toString().substring(0, 6));
            if (pseudoId == entryId) {
              await _accountRepo
                  .save(account.updateMetadata({'sync_privacy': null}));
              break;
            }
          }
        }
      }
      // Reload to get fresh list.
      var policy = await _identityRepo.getSyncPolicy();
      policy = await _resolveLocalNames(policy);
      _emit(_state.copyWith(
        policy: policy,
        isUpdating: false,
        successMessage: AppStrings.theUserHasBeen1,
      ));
    } on AuthException catch (e) {
      _emit(_state.copyWith(
        isUpdating: false,
        error: e.message,
      ));
    } on DioException catch (e) {
      String errorMsg = AppStrings.unableToDeleteUser;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.toString().contains('SocketException')) {
        errorMsg = AppStrings.internetConnectionFailedPlease;
      }
      _emit(_state.copyWith(
        isUpdating: false,
        error: errorMsg,
      ));
    } catch (e) {
      String errorMsg = AppStrings.unableToDeleteUser;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        errorMsg = AppStrings.internetConnectionFailedPlease;
      }
      _emit(_state.copyWith(
        isUpdating: false,
        error: errorMsg,
      ));
    }
  }

  /// Clears any transient messages.
  void clearMessages() {
    _emit(_state.copyWith(clearError: true, clearSuccess: true));
  }
}
