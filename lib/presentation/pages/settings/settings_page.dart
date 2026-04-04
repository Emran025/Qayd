import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/get_account_statement_input.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/groups/backup_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/currency_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/profile_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/security_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/support_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/templates_settings_page.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/excel_data_export.dart';
import 'package:qayd/presentation/utils/share_export_bytes.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return QaydScaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          _CategoryTile(
            icon: Icons.person_outline,
            title: AppStringsAr.settingsGroupProfile,
            onTap: () => _navTo(context, const ProfileSettingsPage()),
          ),
          _CategoryTile(
            icon: Icons.cloud_done_outlined,
            title: AppStringsAr.settingsGroupBackup,
            onTap: () => _navTo(context, const BackupSettingsPage()),
          ),
          _CategoryTile(
            icon: Icons.receipt_long_outlined,
            title: AppStringsAr.settingsGroupTemplates,
            onTap: () => _navTo(context, const TemplatesSettingsPage()),
          ),
          _CategoryTile(
            icon: Icons.currency_exchange_rounded,
            title: AppStringsAr.settingsGroupCurrency,
            onTap: () => _navTo(context, const CurrencySettingsPage()),
          ),
          _CategoryTile(
            icon: Icons.lock_outline,
            title: AppStringsAr.settingsGroupSecurity,
            onTap: () => _navTo(context, const SecuritySettingsPage()),
          ),
          _CategoryTile(
            icon: Icons.support_agent_outlined,
            title: AppStringsAr.settingsGroupSupport,
            onTap: () => _navTo(context, const SupportSettingsPage()),
          ),
          const Divider(),
          const _SectionTitle(AppStringsAr.settingsSectionExport),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(AppStringsAr.settingsExportAllTitle),
            onTap: () => _exportAll(context),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(AppStringsAr.settingsExportVouchersTitle),
            onTap: () => _exportVouchersOnly(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(AppStringsAr.settingsExportStatementTitle),
            onTap: () => _exportStatementPickAccount(context),
          ),
        ],
      ),
    );
  }

  void _navTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      QaydPageRoute.slideFromStart(builder: (_) => page),
    );
  }

  Future<void> _exportAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.settingsExportConfirmTitle),
        content: Text(AppStringsAr.settingsExportConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStringsAr.settingsProceed),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final accountsR = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    final vouchersR = await InjectionContainer.listVouchersUseCase(
      const ListVouchersInput(),
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (accountsR.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accountsR.failureOrNull!.messageAr)),
      );
      return;
    }
    if (vouchersR.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vouchersR.failureOrNull!.messageAr)),
      );
      return;
    }

    final bytes = buildCombinedExportExcelBytes(
      vouchers: vouchersR.valueOrNull!.vouchers,
      accounts: accountsR.valueOrNull!.accounts,
    );
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    await shareExportBytes(
      bytes,
      'qayd_export_$stamp.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _exportVouchersOnly(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final vouchersR = await InjectionContainer.listVouchersUseCase(
      const ListVouchersInput(),
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (vouchersR.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vouchersR.failureOrNull!.messageAr)),
      );
      return;
    }

    final bytes = buildVouchersExcelBytes(vouchersR.valueOrNull!.vouchers);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    await shareExportBytes(
      bytes,
      'qayd_vouchers_$stamp.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _exportStatementPickAccount(BuildContext context) async {
    final accountsR = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    if (!context.mounted) return;
    if (accountsR.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accountsR.failureOrNull!.messageAr)),
      );
      return;
    }
    final accounts = accountsR.valueOrNull!.accounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.accountsEmpty)),
      );
      return;
    }

    String? selectedId = accounts.first.id;
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.settingsExportStatementPickTitle),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedId,
              decoration: InputDecoration(
                labelText: AppStringsAr.pickAccountTitle,
              ),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => selectedId = v),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selectedId),
            child: Text(AppStringsAr.settingsProceed),
          ),
        ],
      ),
    );
    if (id == null || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final stmtR = await InjectionContainer.getAccountStatementUseCase(
      GetAccountStatementInput(accountId: id),
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (stmtR.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stmtR.failureOrNull!.messageAr)),
      );
      return;
    }
    final out = stmtR.valueOrNull!;
    final bytes = buildAccountStatementExcelBytes(
      accountName: out.accountName,
      lines: out.lines,
    );
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safe = out.accountName.replaceAll(RegExp(r'[/\\?*:\[\]]'), '_');
    await shareExportBytes(
      bytes,
      'qayd_statement_${safe}_$stamp.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
