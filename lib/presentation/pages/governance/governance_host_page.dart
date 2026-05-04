import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/governance/governance_ui_state.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/app_shell_page.dart';
import 'package:qayd/presentation/pages/governance/activation_page.dart';
import 'package:qayd/presentation/pages/governance/trial_expired_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Chooses between normal shell, activation gate, and suspended banner overlay.
class GovernanceHostPage extends StatelessWidget {
  const GovernanceHostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GovernanceCubit, GovernanceUiState>(
      builder: (context, state) {
        if (state.isLocked) {
          return const TrialExpiredPage();
        }
        if (state.requiresActivationScreen) {
          return const ActivationPage();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            const AppShellPage(),
            if (state.showSuspendedBanner)
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    elevation: 3,
                    color: ColorTokens.warningAmber.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_clock_rounded,
                            color: ColorTokens.navy950,
                          ),
                          SizedBox(width: SpacingTokens.sm),
                          Expanded(
                            child: QaydText(
                              AppStrings.governanceSuspendedBanner,
                              slot: QaydTextStyleSlot.bodyMedium,
                              color: ColorTokens.navy950,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context
                                .read<GovernanceCubit>()
                                .verifyRemoteStatus(),
                            child: QaydText(
                              AppStrings.governanceRecheckAction,
                              slot: QaydTextStyleSlot.labelLarge,
                              color: ColorTokens.navy950,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
