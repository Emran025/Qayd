import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';
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
    final res = await InjectionContainer.listAccountsUseCase(const ListAccountsInput());
    res.fold((_) {}, (out) {
      setState(() {
        _accounts = out.accounts;
        // Auto-select first liquid asset as source if available
        try {
          _selectedSourceAccountId = _accounts.firstWhere(
            (a) => a.standardClassificationKind == 'liquidAssets' && a.isRoot
          ).id;
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDestAccountId == null) {
       _showError('يرجى اختيار الحساب المستهدف (المصروف).');
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

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    return QaydScaffold(
      appBar: const QaydAppBar(
        title: 'إضافة التزام مالي',
        leading: BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.md),
          children: [
            // ── Name & Amount ─────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'مسمى الالتزام (مثلاً: إيجار الشقة)',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: SpacingTokens.md),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'المبلغ التقديري',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0 ? 'يرجى إدخال مبلغ صالح' : null,
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Frequency ──────────────────────────────────────────────────
            QaydText('تكرار الالتزام', slot: QaydTextStyleSlot.labelLarge, color: scheme.onSurfaceVariant),
            const SizedBox(height: SpacingTokens.sm),
            DropdownButtonFormField<AccrualFrequency>(
              value: _frequency,
              items: AccrualFrequency.values.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f.labelAr),
              )).toList(),
              onChanged: (v) => setState(() => _frequency = v!),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.repeat_rounded)),
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Next Due Date ──────────────────────────────────────────────
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الاستحقاق القادم',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(_nextDueDate)),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Source Account ─────────────────────────────────────────────
            QaydText('حساب الدفع (منين؟)', slot: QaydTextStyleSlot.labelLarge, color: scheme.onSurfaceVariant),
            const SizedBox(height: SpacingTokens.sm),
            DropdownButtonFormField<String>(
              value: _selectedSourceAccountId,
              items: _accounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text(a.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedSourceAccountId = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_balance_rounded),
                hintText: 'اختر حساب الدفع (كاش، بنك...)',
              ),
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Destination Account ────────────────────────────────────────
            QaydText('حساب الاستحقاق (لفين؟)', slot: QaydTextStyleSlot.labelLarge, color: scheme.onSurfaceVariant),
            const SizedBox(height: SpacingTokens.sm),
            DropdownButtonFormField<String>(
              value: _selectedDestAccountId,
              items: _accounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text(a.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedDestAccountId = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_tree_rounded),
                hintText: 'اختر حساب المصروف (سكن، غذاء...)',
              ),
              validator: (v) => v == null ? 'يرجى اختيار الحساب المستهدف' : null,
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Categories (Dimensions) ───────────────────────────────────
            QaydText('البعد الحياتي المرتبط', slot: QaydTextStyleSlot.labelLarge, color: scheme.onSurfaceVariant),
            const SizedBox(height: SpacingTokens.sm),
            Wrap(
              spacing: SpacingTokens.xs,
              runSpacing: SpacingTokens.xs,
              children: CostCenterDimensionCategory.values.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedCategoryId = val ? cat.id : null),
                  selectedColor: gold.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: SpacingTokens.xl),

            // ── Save Button ───────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const CircularProgressIndicator() : const Icon(Icons.check_rounded),
              label: const Text('حفظ الالتزام'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.warningAmber,
                foregroundColor: ColorTokens.navy950,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
