import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/auto_backup_settings_section.dart';
import 'package:qayd/presentation/pages/settings/drive_backup_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsGroupBackup),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          // Auto backup
          _SectionTitle(AppStringsAr.settingsSectionAutoBackup),
          const AutoBackupSettingsSection(),
          const Divider(),

          // Manual backup / restore
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

          // Google Drive backup
          _SectionTitle(AppStringsAr.settingsSectionDriveBackup),
          const DriveBackupSection(),
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
