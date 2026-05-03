import 'package:flutter/material.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/vouchers/conflict_resolution_page.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


class ConflictBanner extends StatelessWidget {
  const ConflictBanner({super.key, required this.proposals});
  final List<NotificationMessage> proposals;

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onErrorContainer.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: QaydText(
              'لديك ${proposals.length} سندات متعارضة (مطابقة لبورصة خارجية).',
              slot: QaydTextStyleSlot.bodySmall,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          TextButton(
            onPressed: () => _openConflictResolution(context),
            child: const Text(AppStringsAr.toTreat),
          ),
        ],
      ),
    );
  }

  void _openConflictResolution(BuildContext context) {
    Navigator.of(context).push(
      ConflictResolutionPage.route(proposals.first),
    );
  }
}
