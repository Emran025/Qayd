import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Toggle, status, and manual-trigger UI for the automatic daily backup.
///
/// Mirrors the WhatsApp local backup UX:
/// - Switch to enable / disable auto-backup.
/// - Shows last backup date.
/// - "Backup Now" triggers an immediate backup.
/// - "Save to Device" copies the backup to external app storage.
class AutoBackupSettingsSection extends StatefulWidget {
  const AutoBackupSettingsSection({super.key});

  @override
  State<AutoBackupSettingsSection> createState() =>
      _AutoBackupSettingsSectionState();
}

class _AutoBackupSettingsSectionState extends State<AutoBackupSettingsSection> {
  bool _loading = true;
  bool _enabled = true;
  DateTime? _lastBackup;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final svc = InjectionContainer.autoBackupService;
    final enabled = await svc.isEnabled();
    final last = await svc.lastBackupDate();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _lastBackup = last;
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    await InjectionContainer.autoBackupService.setEnabled(value);
    await _reload();
  }

  Future<void> _runNow() async {
    setState(() => _working = true);
    final r = await InjectionContainer.autoBackupService.runNow();
    await _reload();
    setState(() => _working = false);
    if (!mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.autoBackupRunNowSuccess)),
      );
    }
  }

  Future<void> _saveToDevice() async {
    setState(() => _working = true);
    final r =
        await InjectionContainer.autoBackupService.saveToExternalStorage();
    setState(() => _working = false);
    if (!mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.autoBackupSavedExternal),
        ),
      );
    }
  }

  Future<void> _saveToPath() async {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = await FilePicker.platform.saveFile(
      dialogTitle: AppStrings.settingsBackupSaveTitle,
      fileName: 'qayd_backup_$stamp.db',
    );
    if (path == null || !mounted) return;
    setState(() => _working = true);
    final r = await InjectionContainer.backupService.saveBackupCopyToPath(path);
    setState(() => _working = false);
    if (!mounted) return;
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.settingsBackupSaved)),
      );
    }
  }

  String get _lastBackupLabel {
    if (_lastBackup == null) return AppStrings.autoBackupNever;
    return DateFormat('yyyy/MM/dd – HH:mm').format(_lastBackup!);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(SpacingTokens.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.backup_outlined),
          title: Text(AppStrings.autoBackupToggleTitle),
          subtitle: Text(AppStrings.autoBackupToggleSubtitle),
          value: _enabled,
          onChanged: _working ? null : _toggleEnabled,
        ),
        ListTile(
          leading: Icon(Icons.history_outlined),
          title: Text(AppStrings.autoBackupLastBackupLabel),
          subtitle: Text(_lastBackupLabel),
          dense: true,
        ),
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
                onPressed: _working ? null : _runNow,
                child: _working
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.autoBackupRunNow),
              ),
              OutlinedButton.icon(
                onPressed: _working ? null : _saveToDevice,
                icon: Icon(Icons.phone_android_outlined, size: 18),
                label: Text(AppStrings.autoBackupSaveToDevice),
              ),
              if (!Platform.isAndroid && !Platform.isIOS)
                OutlinedButton.icon(
                  onPressed: _working ? null : _saveToPath,
                  icon: Icon(Icons.folder_open_outlined, size: 18),
                  label: Text(AppStrings.settingsBackupSaveTitle),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
