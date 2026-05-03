import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/groups/appearance_settings_cubit.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QaydAppBar(title: AppStringsAr.settingsGroupAppearance),
      body: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        builder: (context, state) {
          final cubit = context.read<AppearanceSettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            children: [
              _buildSectionHeader(context, AppStringsAr.appearanceThemeMode),
              _buildSelectionTile<ThemeMode>(
                context,
                title: AppStringsAr.themeSystem,
                icon: Icons.brightness_auto_rounded,
                value: ThemeMode.system,
                groupValue: state.themeMode,
                onChanged: (val) => cubit.updateThemeMode(val!),
              ),
              _buildSelectionTile<ThemeMode>(
                context,
                title: AppStringsAr.themeLight,
                icon: Icons.light_mode_rounded,
                value: ThemeMode.light,
                groupValue: state.themeMode,
                onChanged: (val) => cubit.updateThemeMode(val!),
              ),
              _buildSelectionTile<ThemeMode>(
                context,
                title: AppStringsAr.themeDark,
                icon: Icons.dark_mode_rounded,
                value: ThemeMode.dark,
                groupValue: state.themeMode,
                onChanged: (val) => cubit.updateThemeMode(val!),
              ),
              const SizedBox(height: SpacingTokens.xl),
              _buildSectionHeader(context, AppStringsAr.appearanceLanguage),
              _buildSelectionTile<String>(
                context,
                title: AppStringsAr.langArabic,
                icon: Icons.language_rounded,
                value: 'ar',
                groupValue: state.languageCode,
                onChanged: (val) => cubit.updateLanguage(val!),
              ),
              _buildSelectionTile<String>(
                context,
                title: AppStringsAr.langEnglish,
                icon: Icons.translate_rounded,
                value: 'en',
                groupValue: state.languageCode,
                onChanged: null, // English is coming soon
                subtitle: 'قريباً',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm, right: 4),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSelectionTile<T>(
    BuildContext context, {
    required String title,
    required IconData icon,
    required T value,
    required T groupValue,
    required ValueChanged<T?>? onChanged,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;
    final isDisabled = onChanged == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.dividerColor.withOpacity(0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : () => onChanged(value),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(icon, color: theme.colorScheme.primary, size: 19),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13.5,
                            color:
                                isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
