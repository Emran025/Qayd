import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';

class AssetCreationWizardPage extends StatefulWidget {
  const AssetCreationWizardPage({
    super.key,
    required this.depreciableAssetsRootId,
    required this.profitableAssetsRootId,
  });

  final String? depreciableAssetsRootId;
  final String? profitableAssetsRootId;

  @override
  State<AssetCreationWizardPage> createState() =>
      _AssetCreationWizardPageState();
}

class _AssetCreationWizardPageState extends State<AssetCreationWizardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  String _assetType =
      'investment'; // 'investment' (profitable) or 'possession' (depreciable)
  bool _isSubmitting = false;
  bool _generatesIncome = true;
  CurrencyCode _purchaseCurrency = PredefinedCurrencies.sar;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rootId = _assetType == 'investment'
        ? widget.profitableAssetsRootId
        : widget.depreciableAssetsRootId;

    if (rootId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.errorTheAssetRoot)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final value = double.tryParse(_valueController.text.trim()) ?? 0;
    final sourceType =
        _assetType == 'investment' ? 'investment_asset' : 'possession';

    final metadata = <String, dynamic>{
      'income_source_type': sourceType,
      'purchase_price': value,
      'purchase_currency': _purchaseCurrency.code,
      'currency_code': _purchaseCurrency.code,
      'purchase_date': DateTime.now().toIso8601String(),
      'generates_income': _assetType == 'investment' && _generatesIncome,
    };
    if (_notesController.text.trim().isNotEmpty) {
      metadata['notes'] = _notesController.text.trim();
    }

    final input = CreateAccountInput(
      name: _nameController.text.trim(),
      parentAccountId: rootId,
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
          SnackBar(content: Text(AppStrings.theAssetHasBeen)),
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
      appBar: QaydAppBar(
        title: _assetType == 'investment'
            ? AppStrings.assetWizardInvestmentTitle
            : AppStrings.assetWizardPossessionTitle,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          children: [
            QaydText(
              AppStrings.classificationOfEconomicAsset,
              slot: QaydTextStyleSlot.titleMedium,
            ),
            SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    title: AppStrings.managementInvestmentAssets,
                    description: AppStrings.realEstateStocksMoneymaking,
                    icon: Icons.account_balance_rounded,
                    color: ColorTokens.emerald400,
                    isSelected: _assetType == 'investment',
                    onTap: () => setState(() => _assetType = 'investment'),
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: _TypeCard(
                    title: AppStrings.managementPersonalPossessions,
                    description: AppStrings.carFurniturePersonalItems,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blueAccent,
                    isSelected: _assetType == 'possession',
                    onTap: () => setState(() => _assetType = 'possession'),
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.xl),
            QaydTextField(
              controller: _nameController,
              label: AppStrings.nameOfOriginking,
              hint: AppStrings.buildingCFordCar,
              validator: (v) =>
                  (v == null || v.isEmpty) ? AppStrings.pleaseEnterAName : null,
            ),
            SizedBox(height: SpacingTokens.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: QaydAmountField(
                    controller: _valueController,
                    label: AppStrings.managementAssetValueLabel,
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<CurrencyCode>(
                    initialValue: _purchaseCurrency,
                    decoration: InputDecoration(
                      labelText: AppStrings.acquisitionCurrency,
                      labelStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    items: PredefinedCurrencies.all
                        .where(
                            (c) => c.isActive || c == PredefinedCurrencies.sar)
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.code} (${c.symbol})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _purchaseCurrency = val);
                    },
                  ),
                ),
              ],
            ),
            if (_assetType == 'investment') ...[
              SizedBox(height: SpacingTokens.lg),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_rounded,
                        color: ColorTokens.emerald400),
                    SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QaydText(AppStrings.assetWizardIncomeSourceLabel,
                              slot: QaydTextStyleSlot.labelLarge),
                          Text(AppStrings.theSystemWillAutomatically,
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _generatesIncome,
                      onChanged: (v) => setState(() => _generatesIncome = v),
                      activeThumbColor: ColorTokens.emerald400,
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: SpacingTokens.md),
            QaydTextField(
              controller: _notesController,
              label: AppStrings.referenceDataOptional,
              hint: AppStrings.registrationNumberLocationSpecifications,
              maxLines: 2,
            ),
            SizedBox(height: SpacingTokens.xxl),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: ColorTokens.navy950,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.lg)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(AppStrings.confirmAndRegisterThe,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            SizedBox(height: SpacingTokens.md),
            QaydText(
              AppStrings.aFinancialAccountAnd,
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : scheme.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: isSelected ? color : scheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32, color: isSelected ? color : scheme.onSurfaceVariant),
            SizedBox(height: SpacingTokens.sm),
            QaydText(title,
                slot: QaydTextStyleSlot.labelLarge,
                textAlign: TextAlign.center,
                style: TextStyle(
                    height: 1.1,
                    color: isSelected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant)),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                  fontSize: 9,
                  color:
                      isSelected ? scheme.onSurface : scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
