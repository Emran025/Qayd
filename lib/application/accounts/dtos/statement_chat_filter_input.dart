import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

enum StatementChatViewMode {
  /// Includes user's own claims (uploaded bonds) and what they've accepted.
  /// According to the prompt: includes everything except rejected.
  myAccounts,

  /// Includes what the other party claims and what they've accepted from the user.
  otherPartyAccounts,
}

/// Filter criteria for the Statement of Account chat view.
///
/// Supports filtering by agreement status (color-coded), voucher type & direction,
/// amount range, date range with optional brought-forward balance, and text search.
class StatementChatFilterInput {
  const StatementChatFilterInput({
    this.agreementStatus,
    this.type,
    this.fromDate,
    this.toDate,
    this.searchQuery,
    this.amountMinMinorUnits,
    this.amountMaxMinorUnits,
    this.includePreviousBalance = false,
    this.viewMode = StatementChatViewMode.myAccounts,
  });

  /// Filter by agreement status (maps to color in UI).
  /// null = show all.
  final AgreementStatus? agreementStatus;

  /// Filter by voucher type (receipt / payment).
  /// null = show all.
  final VoucherType? type;

  /// Date range start (inclusive).
  final DateTime? fromDate;

  /// Date range end (inclusive).
  final DateTime? toDate;

  /// Free-text search (voucher number, description, notes, amount).
  final String? searchQuery;

  /// Minimum amount (minor units) inclusive.
  final int? amountMinMinorUnits;

  /// Maximum amount (minor units) inclusive.
  final int? amountMaxMinorUnits;

  /// When true AND [fromDate] is set, include a "brought forward" opening
  /// balance calculated from all vouchers before [fromDate].
  final bool includePreviousBalance;

  /// Perspective for balance calculation and filtering (User vs Other Party).
  final StatementChatViewMode viewMode;

  static const StatementChatFilterInput empty = StatementChatFilterInput();

  bool get hasAny =>
      agreementStatus != null ||
      type != null ||
      fromDate != null ||
      toDate != null ||
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      amountMinMinorUnits != null ||
      amountMaxMinorUnits != null ||
      viewMode != StatementChatViewMode.myAccounts;

  StatementChatFilterInput copyWith({
    AgreementStatus? agreementStatus,
    VoucherType? type,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    int? amountMinMinorUnits,
    int? amountMaxMinorUnits,
    bool? includePreviousBalance,
    StatementChatViewMode? viewMode,
    bool clearAgreementStatus = false,
    bool clearType = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearSearchQuery = false,
    bool clearAmountMin = false,
    bool clearAmountMax = false,
  }) {
    return StatementChatFilterInput(
      agreementStatus:
          clearAgreementStatus ? null : (agreementStatus ?? this.agreementStatus),
      type: clearType ? null : (type ?? this.type),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      amountMinMinorUnits:
          clearAmountMin ? null : (amountMinMinorUnits ?? this.amountMinMinorUnits),
      amountMaxMinorUnits:
          clearAmountMax ? null : (amountMaxMinorUnits ?? this.amountMaxMinorUnits),
      includePreviousBalance:
          includePreviousBalance ?? this.includePreviousBalance,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

