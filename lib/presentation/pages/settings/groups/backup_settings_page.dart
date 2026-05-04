import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/import/import_wizard_page.dart';
import 'package:qayd/presentation/pages/settings/auto_backup_settings_section.dart';
import 'package:qayd/presentation/pages/settings/drive_backup_section.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.settingsGroupBackup),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          // Auto backup
          _SectionTitle(AppStrings.settingsSectionAutoBackup),
          const AutoBackupSettingsSection(),
          const Divider(),

          // Manual backup / restore
          _SectionTitle(AppStrings.settingsSectionBackup),
          ListTile(
            leading: Icon(Icons.cloud_upload_outlined),
            title: Text(AppStrings.settingsBackupShareTitle),
            subtitle: Text(AppStrings.settingsBackupShareSubtitle),
            onTap: () => _confirmBackupShare(context),
          ),
          ListTile(
            leading: Icon(Icons.save_alt_outlined),
            title: Text(AppStrings.settingsBackupSaveTitle),
            subtitle: Text(AppStrings.settingsBackupSaveSubtitle),
            onTap: () => _backupSaveToPath(context),
          ),
          ListTile(
            leading: Icon(Icons.restore_outlined),
            title: Text(AppStrings.settingsRestoreTitle),
            subtitle: Text(AppStrings.settingsRestoreSubtitle),
            onTap: () => _restore(context),
          ),
          const Divider(),

          // Google Drive backup
          _SectionTitle(AppStrings.settingsSectionDriveBackup),
          const DriveBackupSection(),
           Divider(),
           _SectionTitle(AppStrings.importAndImmigration),
          ListTile(
            leading: Icon(Icons.move_to_inbox_rounded),
            title: Text(AppStrings.importAndFormat),
            subtitle: Text(AppStrings.importDataFromAn),
            onTap: () => Navigator.of(context).push(
              QaydPageRoute.slideFromStart(
                  builder: (_) => const ImportWizardPage()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBackupShare(BuildContext context) async {
    final go = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.cloud_upload_outlined,
      title: AppStrings.settingsBackupConfirmTitle,
      content: AppStrings.settingsBackupConfirmBody,
      secondaryActionLabel: AppStrings.templateEditCancel,
      onSecondaryAction: () => Navigator.pop(context, false),
      primaryActionLabel: AppStrings.settingsProceed,
      onPrimaryAction: () => Navigator.pop(context, true),
    );
    if (go != true || !context.mounted) return;
    final r = await InjectionContainer.backupService.shareDatabaseBackup();
    if (!context.mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.failureOrNull!.messageAr)));
    }
  }

  Future<void> _backupSaveToPath(BuildContext context) async {
    final go = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.save_alt_outlined,
      title: AppStrings.settingsBackupConfirmTitle,
      content: AppStrings.settingsBackupConfirmBody,
      secondaryActionLabel: AppStrings.templateEditCancel,
      onSecondaryAction: () => Navigator.pop(context, false),
      primaryActionLabel: AppStrings.settingsProceed,
      onPrimaryAction: () => Navigator.pop(context, true),
    );
    if (go != true || !context.mounted) return;

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    
    // Show a loading indicator if possible or just proceed
    final result = await InjectionContainer.backupService.createUnifiedBackupFile();
    if (!context.mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.messageAr)),
      );
      return;
    }
    final backupFile = result.valueOrNull!;

    final path = await FilePicker.platform.saveFile(
      dialogTitle: AppStrings.settingsBackupSaveTitle,
      fileName: 'qayd_backup_$stamp.qback',
      bytes: await backupFile.readAsBytes(),
    );
    
    if (path == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(AppStrings.settingsBackupSaved)),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final pick = await FilePicker.platform.pickFiles();
    final path = pick?.files.single.path;
    if (path == null || !context.mounted) return;

    final v = await InjectionContainer.backupService.validateBackupFile(path);
    if (!context.mounted) return;
    if (v.isFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(v.failureOrNull!.messageAr)));
      return;
    }

    final go = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: AppStrings.settingsRestoreWarningTitle,
      content: AppStrings.settingsRestoreWarningBody,
      secondaryActionLabel: AppStrings.templateEditCancel,
      onSecondaryAction: () => Navigator.pop(context, false),
      primaryActionLabel: AppStrings.settingsRestoreConfirm,
      onPrimaryAction: () => Navigator.pop(context, true),
    );
    if (go != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
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
        FileSystemFailure(messageAr: '${AppStrings.settingsRestoreError}$e'),
      );
    } finally {
      await InjectionContainer.reopenDatabaseAfterRestore();
    }
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (context.mounted) {
      if (r.isFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(r.failureOrNull!.messageAr)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppStrings.settingsRestoreDone)),
        );
      }
    }
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
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
