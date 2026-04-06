import 'package:qayd/application/accounts/dtos/account_statement_chat_message_dto.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/core/error/failures.dart';

/// Sealed state hierarchy for the Statement of Account chat BLoC.
sealed class StatementChatState {
  const StatementChatState();
}

final class StatementChatInitial extends StatementChatState {
  const StatementChatInitial();
}

final class StatementChatLoading extends StatementChatState {
  const StatementChatLoading();
}

final class StatementChatReady extends StatementChatState {
  const StatementChatReady({
    required this.myAccountId,
    required this.counterpartyAccountId,
    required this.counterpartyName,
    required this.messages,
    required this.broughtForwardMinorUnits,
    required this.finalBalanceMinorUnits,
    required this.filter,
    required this.searchQuery,
    this.isUnified = false,
    this.currencySymbol = '',
    this.currencyDigits = 0,
  });

  final String myAccountId;
  final String counterpartyAccountId;
  final String counterpartyName;
  final List<AccountStatementChatMessageDto> messages;
  final int broughtForwardMinorUnits;
  final int finalBalanceMinorUnits;
  final StatementChatFilterInput filter;
  final String searchQuery;
  final bool isUnified;
  final String currencySymbol;
  final int currencyDigits;

  bool get hasActiveFilters => filter.hasAny || searchQuery.trim().isNotEmpty;

  StatementChatReady copyWith({
    List<AccountStatementChatMessageDto>? messages,
    int? broughtForwardMinorUnits,
    int? finalBalanceMinorUnits,
    StatementChatFilterInput? filter,
    String? searchQuery,
    bool? isUnified,
    String? currencySymbol,
    int? currencyDigits,
  }) {
    return StatementChatReady(
      myAccountId: myAccountId,
      counterpartyAccountId: counterpartyAccountId,
      counterpartyName: counterpartyName,
      messages: messages ?? this.messages,
      broughtForwardMinorUnits:
          broughtForwardMinorUnits ?? this.broughtForwardMinorUnits,
      finalBalanceMinorUnits:
          finalBalanceMinorUnits ?? this.finalBalanceMinorUnits,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isUnified: isUnified ?? this.isUnified,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyDigits: currencyDigits ?? this.currencyDigits,
    );
  }
}

final class StatementChatFailure extends StatementChatState {
  const StatementChatFailure(this.failure);

  final Failure failure;
}
