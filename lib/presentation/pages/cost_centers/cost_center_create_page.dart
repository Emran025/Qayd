import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_extensions.dart';
import 'package:qayd/domain/entities/cost_center.dart';

class CostCenterCreatePage extends StatefulWidget {
  const CostCenterCreatePage({
    super.key,
    required this.onCreated,
    this.initialCostCenter,
  });

  final VoidCallback onCreated;
  final CostCenter? initialCostCenter;

  @override
  State<CostCenterCreatePage> createState() => _CostCenterCreatePageState();
}

class _CostCenterCreatePageState extends State<CostCenterCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();

  CostCenterType _type = CostCenterType.cost;
  bool _saving = false;

  List<CostCenterDimensionCategory> _categories = [];
  final Set<String> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    final c = widget.initialCostCenter;
    if (c != null) {
      _nameController.text = c.name;
      _descController.text = c.description ?? '';
      if (c.hasBudget) {
        _budgetController.text = (c.budgetMinorUnits / 100).toString();
      }
      _type = c.type;
    }
  }

  Future<void> _loadCategories() async {
    final res = await InjectionContainer.manageDimensionsUseCase.listCategories();
    res.fold((_) {}, (cats) => setState(() => _categories = cats));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final budgetText = _budgetController.text.trim();
    int budgetMinor = 0;
    if (budgetText.isNotEmpty) {
      final parsed = double.tryParse(budgetText);
      if (parsed != null) budgetMinor = (parsed * 100).round();
    }

    final Result<void> result;
    if (widget.initialCostCenter != null) {
      result = await InjectionContainer.updateCostCenterUseCase(
        id: widget.initialCostCenter!.id,
        name: _nameController.text.trim(),
        type: _type,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        budgetMinorUnits: budgetMinor,
      );
    } else {
      result = await InjectionContainer.createCostCenterUseCase(
        name: _nameController.text.trim(),
        type: _type,
        currencyCode: 'SAR',
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        budgetMinorUnits: budgetMinor,
        categoryIds: _selectedCategoryIds.toList(),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.messageAr))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStringsAr.costCenterCreatedSnackbar),
          ),
        );
        widget.onCreated();
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCostCenter != null
            ? AppStringsAr.costCenterEditAction
            : AppStringsAr.newCostCenterTitle),
        leading: const BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.md),
          children: [
            // ── Type Selector ──────────────────────────────────────────────
            const SizedBox(height: SpacingTokens.sm),
            QaydText(
              AppStringsAr.costCenterTypeSelectorLabel,
              slot: QaydTextStyleSlot.labelLarge,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    type: CostCenterType.cost,
                    selected: _type == CostCenterType.cost,
                    onTap: () => setState(() => _type = CostCenterType.cost),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: _TypeCard(
                    type: CostCenterType.profit,
                    selected: _type == CostCenterType.profit,
                    onTap: () =>
                        setState(() => _type = CostCenterType.profit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Name ──────────────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStringsAr.costCenterNameHint,
                prefixIcon:
                    const Icon(Icons.label_important_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? AppStringsAr.costCenterNameValidator
                      : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Description ───────────────────────────────────────────────
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: AppStringsAr.costCenterDescHint,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Budget ────────────────────────────────────────────────────
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: AppStringsAr.costCenterBudgetHint,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                hintText: AppStringsAr.costCenterBudgetNoneHint,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),

            // ── Categories (Dimensions) ──────────────────────────────────
            const SizedBox(height: SpacingTokens.md),
            QaydText(
              AppStringsAr.costCenterDimensionSelectorLabel,
              slot: QaydTextStyleSlot.labelLarge,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: SpacingTokens.sm),
            if (_categories.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(SpacingTokens.md),
                child: CircularProgressIndicator(),
              ))
            else
              Wrap(
                spacing: SpacingTokens.xs,
                runSpacing: SpacingTokens.xs,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategoryIds.contains(cat.id);
                  return FilterChip(
                    label: Text(cat.labelAr),
                    selected: isSelected,
                    onSelected: (val) => setState(() => val
                        ? _selectedCategoryIds.add(cat.id)
                        : _selectedCategoryIds.remove(cat.id)),
                    selectedColor: gold.withValues(alpha: 0.2),
                    checkmarkColor: gold,
                  );
                }).toList(),
              ),

            const SizedBox(height: SpacingTokens.xl),

            // ── Save ──────────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(AppStringsAr.costCenterSaveAction),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: ColorTokens.navy950,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final CostCenterType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isProfit = type == CostCenterType.profit;
    final color =
        isProfit ? ColorTokens.emerald600 : ColorTokens.debitBlue;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: SpacingTokens.md,
          horizontal: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow,
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isProfit ? Icons.trending_up_rounded : Icons.pie_chart_rounded,
              color: selected ? color : scheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              type.labelAr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
