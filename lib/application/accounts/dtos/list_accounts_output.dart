import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';

class ListAccountsOutput {
  const ListAccountsOutput({required this.accounts});

  final List<AccountSummaryDto> accounts;
}
