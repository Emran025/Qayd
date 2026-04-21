import 'package:flutter/foundation.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';

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
  }) : _identityRepo = identityRepository;

  final IdentityRepository _identityRepo;

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
      final policy = await _identityRepo.getSyncPolicy();
      _emit(_state.copyWith(policy: policy, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل إعدادات الخصوصية.',
      ));
    }
  }

  /// Updates the sync policy mode on the server.
  Future<void> updatePolicyMode(SyncPolicyMode mode) async {
    _emit(_state.copyWith(isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await _identityRepo.updateSyncPolicy(mode);
      // Reload the full policy to get updated state.
      final policy = await _identityRepo.getSyncPolicy();
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

  /// Adds a user to the access list by phone number.
  Future<void> addToList({
    required String phone,
    required String listType,
  }) async {
    _emit(_state.copyWith(isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await _identityRepo.addToSyncAccessList(
        phone: phone,
        listType: listType,
      );
      // Reload to get fresh list.
      final policy = await _identityRepo.getSyncPolicy();
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
    _emit(_state.copyWith(isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await _identityRepo.removeFromSyncAccessList(entryId: entryId);
      // Reload to get fresh list.
      final policy = await _identityRepo.getSyncPolicy();
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
