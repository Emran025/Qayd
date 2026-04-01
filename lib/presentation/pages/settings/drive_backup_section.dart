import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Google Drive backup section — currently suspended.
///
/// The UI is fully scaffolded so it can be activated in a future release
/// when the Drive integration is ready. All controls are disabled and a
/// clear "suspended" notice is shown to the user.
class DriveBackupSection extends StatelessWidget {
  const DriveBackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Suspended notice banner
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.xs,
          ),
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStringsAr.driveBackupSuspendedNotice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),

        // Drive toggle — disabled while suspended
        SwitchListTile(
          secondary: Icon(
            Icons.add_to_drive_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: Text(
            AppStringsAr.driveBackupToggleTitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          subtitle: Text(
            AppStringsAr.driveBackupToggleSubtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          value: false,
          onChanged: null, // suspended
        ),

        // Account info — disabled while suspended
        ListTile(
          enabled: false,
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(AppStringsAr.driveBackupAccountLabel),
          subtitle: Text(AppStringsAr.driveBackupNoAccount),
        ),

        // Frequency — disabled while suspended
        ListTile(
          enabled: false,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(AppStringsAr.driveBackupFrequencyLabel),
          subtitle: Text(AppStringsAr.driveBackupFrequencyDaily),
          trailing: const Icon(Icons.lock_outline_rounded, size: 18),
        ),

        // Restore from Drive — disabled while suspended
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.xs,
          ),
          child: OutlinedButton.icon(
            onPressed: null, // suspended
            icon: const Icon(Icons.cloud_download_outlined, size: 18),
            label: Text(AppStringsAr.driveBackupRestoreAction),
          ),
        ),
      ],
    );
  }
}
