import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/governance/governance_cubit.dart';
import 'package:qayd/presentation/governance/governance_ui_state.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _formKey = GlobalKey<FormState>();
  final _orgController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _orgController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await context.read<GovernanceCubit>().submitActivation(
          organizationId: _orgController.text,
          licenseKey: _keyController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return BlocListener<GovernanceCubit, GovernanceUiState>(
      listenWhen: (p, c) =>
          c.lastErrorAr != null && c.lastErrorAr != p.lastErrorAr,
      listener: (context, state) {
        final msg = state.lastErrorAr;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                scheme.surface,
                ColorTokens.navy900.withValues(alpha: 0.08),
                scheme.surfaceContainerLow,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: gold.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            QaydText(
                              AppStringsAr.appTitle,
                              slot: QaydTextStyleSlot.displaySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SpacingTokens.xs),
                            QaydText(
                              AppStringsAr.activationSubtitle,
                              slot: QaydTextStyleSlot.bodyMedium,
                              color: scheme.onSurfaceVariant,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SpacingTokens.xl),
                            QaydTextField(
                              controller: _orgController,
                              label: AppStringsAr.activationOrgIdLabel,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return AppStringsAr.activationFieldRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            QaydTextField(
                              controller: _keyController,
                              label: AppStringsAr.activationLicenseLabel,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return AppStringsAr.activationFieldRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: SpacingTokens.xl),
                            BlocBuilder<GovernanceCubit, GovernanceUiState>(
                              builder: (context, state) {
                                final busy = state.refreshInFlight;
                                return FilledButton(
                                  onPressed: busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: ColorTokens.navy950,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: SpacingTokens.md,
                                    ),
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(AppStringsAr.activationSubmit),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
