import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
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

class _AutoBackupSettingsSectionState
    extends State<AutoBackupSettingsSection> {
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
        const SnackBar(content: Text(AppStringsAr.autoBackupRunNowSuccess)),
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
          content: Text(AppStringsAr.autoBackupSavedExternal),
        ),
      );
    }
  }

  Future<void> _saveToPath() async {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = await FilePicker.platform.saveFile(
      dialogTitle: AppStringsAr.settingsBackupSaveTitle,
      fileName: 'qayd_backup_$stamp.db',
    );
    if (path == null || !mounted) return;
    setState(() => _working = true);
    final r =
        await InjectionContainer.backupService.saveBackupCopyToPath(path);
    setState(() => _working = false);
    if (!mounted) return;
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
        SwitchListTile(
          secondary: const Icon(Icons.backup_outlined),
          title: Text(AppStringsAr.autoBackupToggleTitle),
          subtitle: Text(AppStringsAr.autoBackupToggleSubtitle),
          value: _enabled,
          onChanged: _working ? null : _toggleEnabled,
        ),
        ListTile(
          leading: const Icon(Icons.history_outlined),
          title: Text(AppStringsAr.autoBackupLastBackupLabel),
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
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStringsAr.autoBackupRunNow),
              ),
              OutlinedButton.icon(
                onPressed: _working ? null : _saveToDevice,
                icon: const Icon(Icons.phone_android_outlined, size: 18),
                label: Text(AppStringsAr.autoBackupSaveToDevice),
              ),
              if (!Platform.isAndroid && !Platform.isIOS)
                OutlinedButton.icon(
                  onPressed: _working ? null : _saveToPath,
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: Text(AppStringsAr.settingsBackupSaveTitle),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
