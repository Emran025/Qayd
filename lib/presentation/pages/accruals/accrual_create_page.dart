import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:intl/intl.dart';

class AccrualCreatePage extends StatefulWidget {
  const AccrualCreatePage({super.key, this.onCreated});
  final VoidCallback? onCreated;

  @override
  State<AccrualCreatePage> createState() => _AccrualCreatePageState();
}

class _AccrualCreatePageState extends State<AccrualCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  AccrualFrequency _frequency = AccrualFrequency.monthly;
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  String? _selectedCategoryId;
  String? _selectedSourceAccountId;
  String? _selectedDestAccountId;
  String? _selectedCostCenterId;

  bool _saving = false;
  List<AccountSummaryDto> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final res =
        await InjectionContainer.listAccountsUseCase(const ListAccountsInput());
    res.fold((_) {}, (out) {
      setState(() {
        _accounts = out.accounts;
        // Auto-select first liquid asset as source if available
        try {
          _selectedSourceAccountId = _accounts
              .firstWhere((a) =>
                  a.standardClassificationKind == 'liquidAssets' && a.isRoot)
              .id;
        } catch (_) {}
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add( Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDestAccountId == null) {
      _showError(AppStrings.accrualDestAccountRequired);
      return;
    }

    setState(() => _saving = true);

    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    final res = await InjectionContainer.saveAccrualUseCase(
      name: _nameCtrl.text,
      description: _descCtrl.text,
      totalAmountMinor: (amount * 100).toInt(),
      currencyCode: 'SAR',
      sourceAccountId: _selectedSourceAccountId,
      destinationAccountId: _selectedDestAccountId!,
      costCenterId: _selectedCostCenterId,
      categoryId: _selectedCategoryId,
      frequency: _frequency,
      startDate: DateTime.now(),
      nextDueDate: _nextDueDate,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    res.fold(
      (f) => _showError(f.messageAr),
      (_) {
        widget.onCreated?.call();
        Navigator.pop(context);
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Shared compact input decoration ──────────────────────────────────────
  InputDecoration _inputDeco({
    String? labelText,
    String? hintText,
    IconData? icon,
  }) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      isDense: true,
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm + 4,
        vertical: SpacingTokens.sm,
      ),
      labelStyle: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      hintStyle: tt.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: QaydAppBar(
          title: AppStrings.accrualCreateTitle
          // leading: const BackButton(),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            children: [
              // ── Name ────────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                style: tt.bodySmall,
                decoration: _inputDeco(
                  labelText: AppStrings.accrualNameLabel,
                  hintText: AppStrings.accrualNameHint,
                  icon: Icons.label_important_outline_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.accrualNameRequired
                    : null,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(TextSanitizer.emojiRegex, replacementString: ' '),
                ],
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Amount ──────────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                style: tt.bodySmall,
                decoration: _inputDeco(
                  labelText: AppStrings.accrualAmountLabel,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                keyboardType:
                     TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0
                    ? AppStrings.accrualAmountInvalid
                    : null,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(TextSanitizer.emojiRegex, replacementString: ' '),
                ],
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Frequency ───────────────────────────────────────────────
               _SectionLabel(AppStrings.accrualFrequencyLabel),
              SizedBox(height: SpacingTokens.xs),
              DropdownButtonFormField<AccrualFrequency>(
                initialValue: _frequency,
                isDense: true,
                style: tt.bodySmall?.copyWith(color: scheme.onSurface),
                items: AccrualFrequency.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.labelAr),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v!),
                decoration: _inputDeco(icon: Icons.repeat_rounded),
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Next Due Date ───────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                child: InputDecorator(
                  decoration: _inputDeco(
                    labelText: AppStrings.accrualNextDueDateLabel,
                    icon: Icons.calendar_today_rounded,
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_nextDueDate),
                    style: tt.bodySmall,
                  ),
                ),
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Source Account ──────────────────────────────────────────
               _SectionLabel(AppStrings.accrualSourceAccountLabel),
              SizedBox(height: SpacingTokens.xs),
              DropdownButtonFormField<String>(
                initialValue: _selectedSourceAccountId,
                isDense: true,
                style: tt.bodySmall?.copyWith(color: scheme.onSurface),
                items: _accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSourceAccountId = v),
                decoration: _inputDeco(
                  hintText: AppStrings.accrualSourceAccountHint,
                  icon: Icons.account_balance_rounded,
                ),
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Destination Account ─────────────────────────────────────
               _SectionLabel(AppStrings.accrualDestAccountLabel),
              SizedBox(height: SpacingTokens.xs),
              DropdownButtonFormField<String>(
                initialValue: _selectedDestAccountId,
                isDense: true,
                style: tt.bodySmall?.copyWith(color: scheme.onSurface),
                items: _accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDestAccountId = v),
                decoration: _inputDeco(
                  hintText: AppStrings.accrualDestAccountHint,
                  icon: Icons.account_tree_rounded,
                ),
                validator: (v) =>
                    v == null ? AppStrings.accrualDestAccountRequired : null,
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Description ─────────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                style: tt.bodySmall,
                decoration: _inputDeco(
                  labelText: AppStrings.accrualDescriptionLabel,
                  icon: Icons.notes_rounded,
                ),
                maxLines: 2,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(TextSanitizer.emojiRegex, replacementString: ' '),
                ],
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: SpacingTokens.sm + 4),

              // ── Categories (Dimensions) ────────────────────────────────
               _SectionLabel(AppStrings.accrualCategoryLabel),
              SizedBox(height: SpacingTokens.xs),
              Wrap(
                spacing: SpacingTokens.xs,
                runSpacing: SpacingTokens.xs,
                children: CostCenterDimensionCategory.values.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text(
                      cat.name,
                      style: tt.labelSmall?.copyWith(
                        color: isSelected ? gold : scheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) => setState(
                        () => _selectedCategoryId = val ? cat.id : null),
                    selectedColor: gold.withValues(alpha: 0.15),
                    checkmarkColor: gold,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xs,
                      vertical: 0,
                    ),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xs,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: SpacingTokens.lg),

              // ── Save Button ─────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.check_rounded, size: 18),
                label: Text(AppStrings.accrualSaveAction),
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: ColorTokens.navy950,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: SpacingTokens.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact section label matching the app's refined typography.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return QaydText(
      text,
      slot: QaydTextStyleSlot.labelSmall,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
