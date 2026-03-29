import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/settings_page.dart';

/// Opens [SettingsPage] — use on each main tab so the shell stays a single hub without a second app bar.
class SettingsAppBarAction extends StatelessWidget {
  const SettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStringsAr.settingsTitle,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const SettingsPage(),
          ),
        );
      },
    );
  }
}
