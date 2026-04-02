import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/google_drive_backup_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Google Drive backup section — fully functional.
///
/// Allows the user to:
/// - Sign in to Google and enable daily Drive backups.
/// - Manually trigger a backup to Drive.
/// - Restore from a Drive backup.
/// - Sign out and disable Drive backups.
class DriveBackupSection extends StatefulWidget {
  const DriveBackupSection({super.key});

  @override
  State<DriveBackupSection> createState() => _DriveBackupSectionState();
}

class _DriveBackupSectionState extends State<DriveBackupSection> {
  bool _loading = true;
  bool _enabled = false;
  bool _working = false;
  String? _accountEmail;
  DateTime? _lastBackup;

  GoogleDriveBackupService get _svc => InjectionContainer.driveBackupService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final enabled = await _svc.isEnabled();
    final email = _svc.accountEmail ?? await _svc.storedAccountEmail();
    final last = await _svc.lastBackupDate();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _accountEmail = email;
      _lastBackup = last;
      _loading = false;
    });
  }

  // ── Sign-in / Sign-out ──────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _working = true);
    final r = await _svc.signIn();
    if (!mounted) return;
    if (r.isFailure) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
      return;
    }
    // Auto-enable after sign-in.
    await _svc.setEnabled(true);
    await _reload();
    setState(() => _working = false);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.driveBackupSignOutTitle),
        content: Text(AppStringsAr.driveBackupSignOutBody),
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
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    await _svc.signOut();
    await _reload();
    setState(() => _working = false);
  }

  // ── Toggle ────────────────────────────────────────────────────────────────

  Future<void> _toggleEnabled(bool value) async {
    if (value && _accountEmail == null) {
      // Must sign in first.
      await _signIn();
      return;
    }
    await _svc.setEnabled(value);
    await _reload();
  }

  // ── Backup now ────────────────────────────────────────────────────────────

  Future<void> _backupNow() async {
    if (_accountEmail == null) {
      await _signIn();
      if (_accountEmail == null) return;
    }
    setState(() => _working = true);
    final r = await _svc.uploadBackup();
    await _reload();
    setState(() => _working = false);
    if (!mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(AppStringsAr.driveBackupUploadSuccess),
        ),
      );
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Future<void> _restoreFromDrive() async {
    if (_accountEmail == null) {
      await _signIn();
      if (_accountEmail == null) return;
    }

    setState(() => _working = true);

    // 1. Check if a backup exists.
    final check = await _svc.checkForBackup();
    if (!mounted) return;
    if (check.isFailure) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(check.failureOrNull!.messageAr)),
      );
      return;
    }

    final info = check.valueOrNull!;
    setState(() => _working = false);

    // 2. Confirm with user.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.driveBackupRestoreTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStringsAr.driveBackupRestoreBody),
            if (info.lastModified != null) ...[
              const SizedBox(height: SpacingTokens.sm),
              Text(
                '${AppStringsAr.driveBackupLastDate}: '
                '${DateFormat('yyyy/MM/dd – HH:mm').format(info.lastModified!)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ],
        ),
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
    if (confirmed != true || !mounted) return;

    // 3. Show progress.
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

    // 4. Download from Drive.
    final dlResult = await _svc.downloadBackup();
    if (!mounted) return;
    if (dlResult.isFailure) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dlResult.failureOrNull!.messageAr)),
      );
      return;
    }

    final dbPath = dlResult.valueOrNull!;

    // 5. Validate the downloaded file.
    final vResult =
        await InjectionContainer.backupService.validateBackupFile(dbPath);
    if (!mounted) return;
    if (vResult.isFailure) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vResult.failureOrNull!.messageAr)),
      );
      return;
    }

    // 6. Replace DB.
    await InjectionContainer.closeDatabaseForRestore();
    late Result<void> rResult;
    try {
      rResult = await InjectionContainer.backupService
          .replaceDatabaseFromBackupFile(dbPath);
    } catch (e) {
      rResult = FailureResult(
        FileSystemFailure(
          messageAr: '${AppStringsAr.settingsRestoreError}$e',
        ),
      );
    } finally {
      await InjectionContainer.reopenDatabaseAfterRestore();
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (rResult.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rResult.failureOrNull!.messageAr)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.settingsRestoreDone)),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  String get _lastBackupLabel {
    if (_lastBackup == null) return AppStringsAr.autoBackupNever;
    return DateFormat('yyyy/MM/dd – HH:mm').format(_lastBackup!);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(SpacingTokens.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drive toggle.
        SwitchListTile(
          secondary: const Icon(Icons.add_to_drive_outlined),
          title: Text(AppStringsAr.driveBackupToggleTitle),
          subtitle: Text(AppStringsAr.driveBackupToggleSubtitle),
          value: _enabled,
          onChanged: _working ? null : _toggleEnabled,
        ),

        // Account info.
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(AppStringsAr.driveBackupAccountLabel),
          subtitle: Text(_accountEmail ?? AppStringsAr.driveBackupNoAccount),
          trailing: _accountEmail != null
              ? TextButton(
                  onPressed: _working ? null : _signOut,
                  child: Text(AppStringsAr.driveBackupSignOut),
                )
              : TextButton(
                  onPressed: _working ? null : _signIn,
                  child: Text(AppStringsAr.driveBackupSignIn),
                ),
        ),

        // Last backup.
        ListTile(
          leading: const Icon(Icons.history_outlined),
          title: Text(AppStringsAr.driveBackupLastDate),
          subtitle: Text(_lastBackupLabel),
          dense: true,
        ),

        // Frequency.
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text(AppStringsAr.driveBackupFrequencyLabel),
          subtitle: Text(AppStringsAr.driveBackupFrequencyDaily),
        ),

        // Action buttons.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.xs,
          ),
          child: Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.xs,
            children: [
              FilledButton.tonal(
                onPressed: _working ? null : _backupNow,
                child: _working
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStringsAr.driveBackupNow),
              ),
              OutlinedButton.icon(
                onPressed: _working ? null : _restoreFromDrive,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(AppStringsAr.driveBackupRestoreAction),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
