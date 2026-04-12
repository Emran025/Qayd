import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/accounts/archived_accounts_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// A sleek and professional helper to confirm and execute account archival.
Future<void> confirmAndArchiveAccount(
    BuildContext context, String accountId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
        icon: Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.archive_outlined, size: 32, color: scheme.error),
        ),
        title: QaydText(
          AppStringsAr.archiveAccountAction,
          slot: QaydTextStyleSlot.titleLarge,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SpacingTokens.sm),
            QaydText(
              AppStringsAr.archiveAccountWarningText,
              slot: QaydTextStyleSlot.bodyMedium,
              color: scheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(
          bottom: SpacingTokens.lg,
          left: SpacingTokens.lg,
          right: SpacingTokens.lg,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md)),
                  ),
                  child: Text(AppStringsAr.actionCancel),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    padding:
                        const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md)),
                  ),
                  child: const Text(AppStringsAr.archiveAccountConfirm),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  final result = await InjectionContainer.archiveAccountUseCase(accountId);
  if (!context.mounted) return;

  if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStringsAr.archiveAccountSuccess)),
    );
    Navigator.pop(context); // Go back to the previous List page
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull!.messageAr)),
    );
  }
}

/// A sleek and professional helper to confirm and execute account restoration.
Future<void> confirmAndRestoreAccount(
    BuildContext context, String accountId, String accountName) async {
  showDialog(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
        icon: Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.unarchive_outlined, size: 32, color: scheme.primary),
        ),
        title: QaydText(
          AppStringsAr.restoreAccountTitle,
          slot: QaydTextStyleSlot.titleLarge,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SpacingTokens.sm),
            QaydText(
              AppStringsAr.restoreAccountWarning(accountName),
              slot: QaydTextStyleSlot.bodyMedium,
              color: scheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(
          bottom: SpacingTokens.lg,
          left: SpacingTokens.lg,
          right: SpacingTokens.lg,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md)),
                  ),
                  child: Text(AppStringsAr.actionCancel),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<ArchivedAccountsCubit>().restore(
                          accountId,
                          (error) => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error))),
                          () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      AppStringsAr.restoreAccountSuccess))),
                        );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md)),
                  ),
                  child: const Text(AppStringsAr.restoreAccountConfirm),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
