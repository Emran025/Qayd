import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/cost_center_tag_selector.dart';

/// Wizard for creating a "Profession / Freelance" income source account.
///
/// Creates a child account under the `personalRevenues` root with
/// `income_source_type: 'profession'` metadata.
class ProfessionCreationWizardPage extends StatefulWidget {
  const ProfessionCreationWizardPage({
    super.key,
    required this.personalRevenuesRootId,
  });

  final String? personalRevenuesRootId;

  @override
  State<ProfessionCreationWizardPage> createState() =>
      _ProfessionCreationWizardPageState();
}

class _ProfessionCreationWizardPageState
    extends State<ProfessionCreationWizardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  bool _isSubmitting = false;

  List<CostCenterTagInput> _costCenterTags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _professionNameController.dispose();
    _licenseController.dispose();
    _hourlyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.personalRevenuesRootId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.professionWizardRootError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final metadata = <String, dynamic>{
      'income_source_type': 'profession',
      'profession_name': _professionNameController.text.trim(),
    };
    if (_licenseController.text.trim().isNotEmpty) {
      metadata['license_number'] = _licenseController.text.trim();
    }
    if (_startDate != null) {
      metadata['start_date'] = _startDate!.toIso8601String();
    }
    final hourlyRate = double.tryParse(_hourlyRateController.text.trim());
    if (hourlyRate != null && hourlyRate > 0) {
      metadata['hourly_rate'] = hourlyRate;
    }
    if (_notesController.text.trim().isNotEmpty) {
      metadata['notes'] = _notesController.text.trim();
    }

    final input = CreateAccountInput(
      name: _nameController.text.trim(),
      parentAccountId: widget.personalRevenuesRootId,
      defaultCostCenters: _costCenterTags,
      metadata: metadata,
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
          SnackBar(content: Text(AppStrings.professionWizardSuccess)),
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
      appBar: QaydAppBar(title: AppStrings.professionWizardTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          children: [
            // Header icon
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: ColorTokens.debitBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                border: Border.all(
                  color: ColorTokens.debitBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.work_outline_rounded,
                      size: 36, color: ColorTokens.debitBlue),
                  SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QaydText(
                          AppStrings.professionWizardTitle,
                          slot: QaydTextStyleSlot.titleMedium,
                        ),
                        SizedBox(height: 2),
                        Text(
                          AppStrings.professionWizardDesc,
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
              label: AppStrings.professionAccountNameLabel,
              hint: AppStrings.professionAccountNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.professionAccountNameRequired
                  : null,
            ),

            SizedBox(height: SpacingTokens.md),

            QaydTextField(
              controller: _professionNameController,
              label: AppStrings.professionNameLabel,
              hint: AppStrings.professionNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.professionNameRequired
                  : null,
            ),

            SizedBox(height: SpacingTokens.md),

            QaydTextField(
              controller: _licenseController,
              label: AppStrings.professionLicenseLabel,
              hint: AppStrings.professionLicenseHint,
            ),

            SizedBox(height: SpacingTokens.md),

            QaydAmountField(
              controller: _hourlyRateController,
              label: AppStrings.professionHourlyRateLabel,
            ),

            SizedBox(height: SpacingTokens.md),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: QaydText(
                AppStrings.professionStartDateLabel,
                slot: QaydTextStyleSlot.labelLarge,
                color: scheme.onSurfaceVariant,
              ),
              subtitle: QaydText(
                _startDate != null
                    ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                    : AppStrings.professionStartDateHint,
                slot: QaydTextStyleSlot.bodyLarge,
              ),
              trailing: Icon(Icons.calendar_month_rounded, color: gold),
              onTap: _pickStartDate,
            ),

            SizedBox(height: SpacingTokens.md),

            QaydTextField(
              controller: _notesController,
              label: AppStrings.professionNotesLabel,
              hint: AppStrings.professionNotesHint,
              maxLines: 2,
            ),

            SizedBox(height: SpacingTokens.md),

            QaydText(
              AppStrings.defaultCostCentersTitle,
              slot: QaydTextStyleSlot.titleMedium,
            ),
            SizedBox(height: SpacingTokens.md),
            CostCenterTagSelector(
              initialTags: _costCenterTags,
              onChanged: (tags) => setState(() => _costCenterTags = tags),
              label: AppStrings.professionAddCostCenter,
            ),

            SizedBox(height: SpacingTokens.xxl),

            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: ColorTokens.navy950,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2)
                  : Text(
                      AppStrings.professionSubmitButton,
                      style:  TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),

            SizedBox(height: SpacingTokens.md),
            QaydText(
              AppStrings.professionSubmitNote,
              slot: QaydTextStyleSlot.labelSmall,
              color: scheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
