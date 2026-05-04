import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/utils/statement_chat_export.dart';
import 'package:qayd/application/accounts/dtos/account_statement_chat_message_dto.dart';
import 'package:qayd/core/result/result.dart';

/// Fetches statement data in "Chat" style and shares it as PDF.
Future<void> shareAccountStatementChatAsPdf(
  BuildContext context, {
  required String accountId,
  required String accountName,
}) async {
  final data = await _fetchChatData(accountId, accountName);
  if (data == null || !context.mounted) return;

  await shareStatementChatAsPdf(
    context,
    accountId: accountId,
    accountName: data.accountName,
    filter: data.filter,
    messages: data.messages,
    broughtForwardByCurrency: data.broughtForwardByCurrency,
    finalBalanceByCurrency: data.finalBalanceByCurrency,
    natureCode: data.natureCode,
  );
}

/// Fetches statement data in "Chat" style and shares it as Excel.
Future<void> shareAccountStatementChatAsExcel(
  BuildContext context, {
  required String accountId,
  required String accountName,
}) async {
  final data = await _fetchChatData(accountId, accountName);
  if (data == null || !context.mounted) return;

  // Infer currency digits from first message or default to 2
  int digits = 2;
  if (data.messages.isNotEmpty) {
    digits = data.messages.first.currencyDigits;
  }

  await shareStatementChatAsExcel(
    context,
    accountId: accountId,
    accountName: data.accountName,
    filter: data.filter,
    messages: data.messages,
    broughtForwardByCurrency: data.broughtForwardByCurrency,
    currencyDigits: digits,
  );
}

/// Helper to fetch the "Chat" style data by replicating StatementChatCubit logic.
Future<_ChatStatementData?> _fetchChatData(
  String counterpartyAccountId,
  String initialAccountName,
) async {
  final accountsR = await InjectionContainer.listAccountsUseCase.call(
    const ListAccountsInput(activeOnly: false),
  );
  if (accountsR.isFailure) return null;

  final accounts = accountsR.valueOrNull!.accounts;
  final cpIndex = accounts.indexWhere((a) => a.id == counterpartyAccountId);

  String accountName = initialAccountName;
  bool isUnified = false;
  String natureCode = 'credit';

  if (cpIndex != -1) {
    final cp = accounts[cpIndex];
    accountName = cp.name;
    isUnified = cp.standardClassificationKind ==
        StandardAccountClassificationKind.liquidAssets.name;
    natureCode = cp.natureCode;
  } else {
    isUnified =
        true; // Assume unified for non-account entities (like cost centers)
  }

  // Pick the "my" account (Fund account)
  final fundAccount = accounts.firstWhere(
    (a) =>
        a.standardClassificationKind ==
            StandardAccountClassificationKind.liquidAssets.name &&
        a.id != counterpartyAccountId,
    orElse: () => accounts.firstWhere(
      (a) => a.id != counterpartyAccountId,
      orElse: () => accounts.first,
    ),
  );
  final myAccountId = fundAccount.id;

  final filter = StatementChatFilterInput.empty;
  final result = await InjectionContainer.listAccountStatementChatUseCase.call(
    myAccountId: myAccountId,
    counterpartyAccountId: counterpartyAccountId,
    filter: filter,
    isUnified: isUnified,
  );

  if (result.isFailure) return null;
  final out = result.valueOrNull!;

  return _ChatStatementData(
    accountName: accountName,
    messages: out.messages,
    broughtForwardByCurrency: out.broughtForwardByCurrency,
    finalBalanceByCurrency: out.finalBalanceByCurrency,
    filter: filter,
    natureCode: natureCode,
  );
}

class _ChatStatementData {
  final String accountName;
  final List<AccountStatementChatMessageDto> messages;
  final Map<String, int> broughtForwardByCurrency;
  final Map<String, int> finalBalanceByCurrency;
  final StatementChatFilterInput filter;
  final String natureCode;

  _ChatStatementData({
    required this.accountName,
    required this.messages,
    required this.broughtForwardByCurrency,
    required this.finalBalanceByCurrency,
    required this.filter,
    required this.natureCode,
  });
}
