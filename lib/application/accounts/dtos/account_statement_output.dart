import 'package:qayd/application/accounts/dtos/account_statement_line_dto.dart';

class AccountStatementOutput {
  const AccountStatementOutput({
    required this.accountId,
    required this.accountName,
    required this.natureCode,
    required this.lines,
  });

  final String accountId;
  final String accountName;
  final String natureCode;
  final List<AccountStatementLineDto> lines;
}
