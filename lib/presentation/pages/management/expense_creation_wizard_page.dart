import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// Wizard for creating a new Expense Category.
/// Extremely simple, since expense categories just act as buckets.
class ExpenseCreationWizardPage extends StatefulWidget {
  const ExpenseCreationWizardPage({
    super.key,
    required this.personalExpensesRootId,
  });

  final String? personalExpensesRootId;

  @override
  State<ExpenseCreationWizardPage> createState() =>
      _ExpenseCreationWizardPageState();
}

class _ExpenseCreationWizardPageState extends State<ExpenseCreationWizardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.personalExpensesRootId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.expenseWizardRootError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final input = CreateAccountInput(
      name: _nameController.text.trim(),
      parentAccountId: widget.personalExpensesRootId,
      metadata: const {
        'classification': 'personal_expense',
      },
    );

    final result = await InjectionContainer.createAccountUseCase(input);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.messageAr)),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.expenseWizardSuccess)),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar:  QaydAppBar(title: AppStrings.expenseWizardTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          children: [
            // Header icon
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: ColorTokens.errorSoft.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                border: Border.all(
                  color: ColorTokens.errorSoft.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 36, color: ColorTokens.errorSoft),
                  SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QaydText(
                          AppStrings.expenseWizardHeaderTitle,
                          slot: QaydTextStyleSlot.titleMedium,
                        ),
                        SizedBox(height: 2),
                        Text(
                          AppStrings.expenseWizardHeaderDesc,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: SpacingTokens.xl),

            QaydTextField(
              controller: _nameController,
              label: AppStrings.expenseWizardNameLabel,
              hint: AppStrings.expenseWizardNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.expenseWizardNameRequired
                  : null,
            ),

            SizedBox(height: SpacingTokens.xxl),

            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: ColorTokens.navy950,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2)
                  : Text(
                      AppStrings.expenseWizardSubmit,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
