import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/governance/governance_ui_state.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class TrialExpiredPage extends StatelessWidget {
  const TrialExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return BlocBuilder<GovernanceCubit, GovernanceUiState>(
      builder: (context, state) {
        final account = state.ownerAccountNumber ?? '...';

        return Scaffold(
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  ColorTokens.navy950,
                  ColorTokens.navy900,
                  scheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              ColorTokens.warningAmber.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.lock_clock_rounded,
                          size: 64,
                          color: ColorTokens.warningAmber,
                        ),
                      ),
                      SizedBox(height: SpacingTokens.xl),
                      QaydText(
                        AppStrings.vaultTrialExpiredTitle,
                        slot: QaydTextStyleSlot.displaySmall,
                        textAlign: TextAlign.center,
                        color: scheme.onSurface,
                      ),
                      SizedBox(height: SpacingTokens.md),
                      QaydText(
                        state.statusMessage ??
                            AppStrings.vaultTrialExpiredBody,
                        slot: QaydTextStyleSlot.bodyMedium,
                        textAlign: TextAlign.center,
                        color: scheme.onSurfaceVariant,
                      ),
                      SizedBox(height: SpacingTokens.xxl),

                      // Payment Section
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            QaydText(
                              AppStrings.governancePaymentInstruction,
                              slot: QaydTextStyleSlot.labelLarge,
                              color: scheme.onSurface,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: SpacingTokens.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: SpacingTokens.md,
                                horizontal: SpacingTokens.lg,
                              ),
                              decoration: BoxDecoration(
                                color: ColorTokens.navy950,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      color: gold, size: 20),
                                  SizedBox(width: SpacingTokens.md),
                                  SelectableText(
                                    account,
                                    style: TextStyle(
                                      color: gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: SpacingTokens.md),
                            QaydText(
                              AppStrings.governanceContactAdmin,
                              slot: QaydTextStyleSlot.bodySmall,
                              color: scheme.onSurfaceVariant,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: SpacingTokens.xxl),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: state.refreshInFlight
                              ? null
                              : () => context
                                  .read<GovernanceCubit>()
                                  .verifyRemoteStatus(),
                          icon: state.refreshInFlight
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.refresh_rounded),
                          label: Text(AppStrings.governanceRecheckAction),
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: ColorTokens.navy950,
                            padding: const EdgeInsets.all(SpacingTokens.md),
                          ),
                        ),
                      ),

                      SizedBox(height: SpacingTokens.md),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(
                            '/activation'), // Link back to activation if they have a key
                        child: Text(AppStrings.backToLogin,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
