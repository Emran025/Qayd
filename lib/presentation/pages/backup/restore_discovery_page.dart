import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/backup/restore_cubit.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


class RestoreDiscoveryPage extends StatelessWidget {
  const RestoreDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: BlocConsumer<RestoreCubit, RestoreState>(
        listener: (context, state) {
          if (state is RestoreSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.theDataHasBeen)),
            );
            Navigator.of(context).pop(true);
          } else if (state is RestoreFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorAr)));
          } else if (state is RestoreNeedsPrimaryKey) {
            _showPrimaryKeyDialog(context, state.backupPath);
          } else if (state is RestoreNoBackupFound) {
            Navigator.of(context).pop(false); // Go to fresh app
          }
        },
        builder: (context, state) {
          if (state is RestoreFound) {
            return _buildFoundUI(context, state);
          }
          return Center(
            child: CircularProgressIndicator(color: ColorTokens.emerald500),
          );
        },
      ),
    );
  }

  Widget _buildFoundUI(BuildContext context, RestoreFound state) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final localMod = state.localFile.existsSync()
        ? state.localFile.lastModifiedSync()
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.xl,
        ),
        child: Column(
          children: [
             AuthAnimatedIcon(
              iconData: Icons.cloud_download_rounded,
              iconColor: ColorTokens.emerald500,
            ),
            SizedBox(height: SpacingTokens.lg),
             AuthTitleBlock(
              title: AppStrings.weFoundABackup,
              subtitle:
                  AppStrings.thereIsAPrevious,
            ),
            SizedBox(height: SpacingTokens.xl),
            if (state.localFile.existsSync()) ...[
              _buildBackupCard(
                context,
                title: AppStrings.localCopyOnThe,
                subtitle:
                    'بتاريخ: ${localMod != null ? dateFormat.format(localMod) : AppStrings.unknown}',
                onTap: () => context.read<RestoreCubit>().performRestore(
                      localFile: state.localFile,
                    ),
              ),
              SizedBox(height: SpacingTokens.sm),
            ],
            if (state.driveInfo != null) ...[
              _buildBackupCard(
                context,
                title: AppStrings.copyFromGoogleDrive,
                subtitle:
                    'بتاريخ: ${state.driveInfo!.lastModified != null ? dateFormat.format(state.driveInfo!.lastModified!) : AppStrings.unknown}',
                onTap: () => context.read<RestoreCubit>().performRestore(
                      fromDrive: true,
                    ),
              ),
              SizedBox(height: SpacingTokens.sm),
            ],
            const Spacer(),
            AuthSubmitButton(
              label: AppStrings.restoreTheSelectedVersion,
              loading: state is RestoreInProgess,
              onPressed: () {
                // If there's only one, we can define a default or just use the card clicks
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppStrings.skipAndStartWith,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SpacingTokens.md),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
        ),
        trailing: Icon(
          Icons.restore_rounded,
          color: theme.colorScheme.primary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPrimaryKeyDialog(BuildContext context, String path) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    QaydDialog.show(
      context: context,
      icon: Icons.vpn_key_rounded,
      title: AppStrings.encryptionKeyRequired,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QaydText(
            AppStrings.pleaseEnterThePrimary,
            slot: QaydTextStyleSlot.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SpacingTokens.md),
          TextField(
            controller: controller,
            maxLines: 4,
            cursorColor: theme.colorScheme.primary,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              hintText: AppStrings.enterRecoveryPhraseHere,
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      secondaryActionLabel: AppStrings.cancellation,
      onSecondaryAction: () => Navigator.pop(context),
      primaryActionLabel: AppStrings.confirmAndDecrypt,
      onPrimaryAction: () {
        final phrase = controller.text.trim();
        if (phrase.isNotEmpty) {
          Navigator.pop(context);
          context.read<RestoreCubit>().restoreWithPrimaryKey(
                path,
                phrase,
              );
        }
      },
    );
  }
}
