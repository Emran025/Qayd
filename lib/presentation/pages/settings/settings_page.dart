import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/csv_accounts_import_draft.dart';
import 'package:qayd/application/accounts/dtos/get_account_statement_input.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_input.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/l10n/classification_labels.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/settings_security_section.dart';
import 'package:qayd/presentation/pages/settings/currency_management_screen.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/excel_data_export.dart';
import 'package:qayd/presentation/utils/share_export_bytes.dart';

/// Backup, restore, Excel export, CSV import, and security.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          _SectionTitle(AppStringsAr.settingsSectionBackup),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(AppStringsAr.settingsBackupShareTitle),
            subtitle: Text(AppStringsAr.settingsBackupShareSubtitle),
            onTap: () => _confirmBackupShare(context),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt_outlined),
            title: Text(AppStringsAr.settingsBackupSaveTitle),
            subtitle: Text(AppStringsAr.settingsBackupSaveSubtitle),
            onTap: () => _backupSaveToPath(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text(AppStringsAr.settingsRestoreTitle),
            subtitle: Text(AppStringsAr.settingsRestoreSubtitle),
            onTap: () => _restore(context),
          ),
          const Divider(),
          _SectionTitle(AppStringsAr.settingsSectionExport),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(AppStringsAr.settingsExportAllTitle),
            subtitle: Text(AppStringsAr.settingsExportAllSubtitle),
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
            subtitle: Text(AppStringsAr.settingsExportStatementSubtitle),
            onTap: () => _exportStatementPickAccount(context),
          ),
          const Divider(),
          _SectionTitle(AppStringsAr.settingsSectionSecurity),
          const SettingsSecuritySection(),
          const Divider(),
          _SectionTitle(AppStringsAr.settingsSectionCurrency),
          ListTile(
            leading: const Icon(Icons.currency_exchange_rounded),
            title: const Text('إعدادات العملات الأساسية'),
            subtitle: const Text('إدارة العملات والعملة الافتراضية للتطبيق.'),
            onTap: () => Navigator.of(context).push(
              QaydPageRoute.slideFromStart(
                builder: (ctx) => const CurrencyManagementScreen(),
              ),
            ),
          ),
          const Divider(),
          _SectionTitle(AppStringsAr.settingsSectionDraft),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(AppStringsAr.settingsCsvImportTitle),
            subtitle: Text(AppStringsAr.settingsCsvImportSubtitle),
            onTap: () => _csvImportAccounts(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBackupShare(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.settingsBackupConfirmTitle),
        content: Text(AppStringsAr.settingsBackupConfirmBody),
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
    if (go != true || !context.mounted) return;
    final r = await InjectionContainer.backupService.shareDatabaseBackup();
    if (!context.mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    }
  }

  Future<void> _backupSaveToPath(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.settingsBackupConfirmTitle),
        content: Text(AppStringsAr.settingsBackupConfirmBody),
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
    if (go != true || !context.mounted) return;

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = await FilePicker.platform.saveFile(
      dialogTitle: AppStringsAr.settingsBackupSaveTitle,
      fileName: 'qayd_backup_$stamp.db',
    );
    if (path == null || !context.mounted) return;
    final r = await InjectionContainer.backupService.saveBackupCopyToPath(path);
    if (!context.mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.settingsBackupSaved)),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    final pick = await FilePicker.platform.pickFiles();
    final path = pick?.files.single.path;
    if (path == null || !context.mounted) return;

    final v = await InjectionContainer.backupService.validateBackupFile(path);
    if (!context.mounted) return;
    if (v.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v.failureOrNull!.messageAr)),
      );
      return;
    }

    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.settingsRestoreWarningTitle),
        content: Text(AppStringsAr.settingsRestoreWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.onError,
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStringsAr.settingsRestoreConfirm),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

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

    await InjectionContainer.closeDatabaseForRestore();
    late Result<void> r;
    try {
      r = await InjectionContainer.backupService.replaceDatabaseFromBackupFile(
        path,
      );
    } catch (e) {
      r = FailureResult(
        FileSystemFailure(messageAr: '${AppStringsAr.settingsRestoreError}$e'),
      );
    } finally {
      await InjectionContainer.reopenDatabaseAfterRestore();
    }
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (context.mounted) {
      if (r.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.failureOrNull!.messageAr)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStringsAr.settingsRestoreDone)),
        );
      }
    }
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

  Future<void> _csvImportAccounts(BuildContext context) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );
    final path = pick?.files.single.path;
    if (path == null || !context.mounted) return;

    final text = await File(path).readAsString();
    final parsed = CsvAccountsImportDraft.parse(text);
    if (!context.mounted) return;
    if (parsed.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parsed.failureOrNull!.messageAr)),
      );
      return;
    }
    final rows = parsed.valueOrNull!;
    var defaultKind = StandardAccountClassificationKind.settlements;

    final preview = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(AppStringsAr.settingsCsvPreviewTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStringsAr.settingsCsvPreviewBody(rows.length)),
                  const SizedBox(height: 16),
                  Text(AppStringsAr.settingsCsvDefaultClassification),
                  DropdownButtonFormField<StandardAccountClassificationKind>(
                    value: defaultKind,
                    items: [
                      for (final k in StandardAccountClassificationKind.values)
                        DropdownMenuItem(
                          value: k,
                          child: Text(standardClassificationKindLabelAr(k)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => defaultKind = v);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStringsAr.templateEditCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppStringsAr.settingsCsvImportExecute),
              ),
            ],
          );
        },
      ),
    );
    if (preview != true || !context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.settingsCsvImportConfirmTitle),
        content: Text(AppStringsAr.settingsCsvImportConfirmBody(rows.length)),
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
    if (confirm != true || !context.mounted) return;

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

    final batchR = await InjectionContainer.batchImportAccountsFromCsvUseCase(
      rows: rows,
      defaultRootKind: defaultKind,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final out = batchR.valueOrNull!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStringsAr.settingsCsvImportDone(
            out.createdCount,
            out.failures.length,
          ),
        ),
      ),
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
