import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Multi-step bottom sheet for the collateral liquidation / sale workflow.
///
/// Steps:
/// 1. Choose settlement type (Voucher Only / Full Debt)
/// 2. Enter actual sale value
/// 3. Review auto-generated entries
/// 4. Confirm & execute
class LiquidationWizardSheet extends StatefulWidget {
  const LiquidationWizardSheet({
    super.key,
    required this.collateralDescription,
    required this.voucherAmountMinor,
    required this.totalDebtMinor,
    required this.currencyCode,
    required this.onConfirm,
  });

  final String collateralDescription;
  final int voucherAmountMinor;
  final int totalDebtMinor;
  final String currencyCode;

  /// Called with (settlementType, saleValueMinor).
  final void Function(String settlementType, int saleValueMinor) onConfirm;

  static Future<void> show(
    BuildContext context, {
    required String collateralDescription,
    required int voucherAmountMinor,
    required int totalDebtMinor,
    required String currencyCode,
    required void Function(String settlementType, int saleValueMinor) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => LiquidationWizardSheet(
        collateralDescription: collateralDescription,
        voucherAmountMinor: voucherAmountMinor,
        totalDebtMinor: totalDebtMinor,
        currencyCode: currencyCode,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<LiquidationWizardSheet> createState() =>
      _LiquidationWizardSheetState();
}

class _LiquidationWizardSheetState extends State<LiquidationWizardSheet> {
  int _step = 0;
  String _settlementType = 'voucher';
  final _saleValueController = TextEditingController();

  int get _debtMinor =>
      _settlementType == 'full_debt'
          ? widget.totalDebtMinor
          : widget.voucherAmountMinor;

  int get _saleValueMinor {
    final text = _saleValueController.text.replaceAll(',', '');
    return ((double.tryParse(text) ?? 0) * 100).toInt();
  }

  int get _surplusMinor {
    final surplus = _saleValueMinor - _debtMinor;
    return surplus > 0 ? surplus : 0;
  }

  @override
  void dispose() {
    _saleValueController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1 && _saleValueMinor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال قيمة البيع')),
      );
      return;
    }
    setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  void _confirm() {
    widget.onConfirm(_settlementType, _saleValueMinor);
    Navigator.of(context).pop();
  }

  String _formatMinor(int minor) =>
      NumberFormat.decimalPattern('ar').format(minor / 100);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = ColorTokens.goldAccent;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Icon(Icons.gavel_rounded, color: scheme.error, size: 24),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    'تصفية رهن',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                child: Row(
                  children: List.generate(3, (i) {
                    final isActive = i <= _step;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive ? gold : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: SpacingTokens.md),

              // Step content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_step) {
                  0 => _buildStep1(gold),
                  1 => _buildStep2(gold),
                  _ => _buildStep3(gold),
                },
              ),

              const SizedBox(height: SpacingTokens.xl),

              // Navigation
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: Text('رجوع',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  const Spacer(),
                  if (_step < 2)
                    FilledButton(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(backgroundColor: gold),
                      child: Text(
                        'التالي',
                        style: TextStyle(color: scheme.surface),
                      ),
                    ),
                  if (_step == 2)
                    FilledButton.icon(
                      onPressed: _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('تأكيد التصفية'),
                    ),
                ],
              ),

              const SizedBox(height: SpacingTokens.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(Color gold) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع التسوية',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        _SettlementOption(
          title: 'تسوية السند فقط',
          subtitle:
              'تغطية مبلغ السند المرتبط (${_formatMinor(widget.voucherAmountMinor)} ${widget.currencyCode})',
          isSelected: _settlementType == 'voucher',
          onTap: () => setState(() => _settlementType = 'voucher'),
        ),
        const SizedBox(height: SpacingTokens.sm),
        _SettlementOption(
          title: 'تسوية الدين الكامل',
          subtitle:
              'تغطية إجمالي الرصيد المستحق (${_formatMinor(widget.totalDebtMinor)} ${widget.currencyCode})',
          isSelected: _settlementType == 'full_debt',
          onTap: () => setState(() => _settlementType = 'full_debt'),
        ),
      ],
    );
  }

  Widget _buildStep2(Color gold) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قيمة البيع الفعلية',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'أدخل المبلغ الذي تم بيع الرهن "${widget.collateralDescription}" به',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.outline,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        QaydAmountField(
          controller: _saleValueController,
          label: 'قيمة البيع (${widget.currencyCode})',
        ),
      ],
    );
  }

  Widget _buildStep3(Color gold) {
    final scheme = Theme.of(context).colorScheme;
    final settledAmount =
        _saleValueMinor >= _debtMinor ? _debtMinor : _saleValueMinor;

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مراجعة القيود المحاسبية',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),

        // Entry 1: Settlement
        _EntryPreview(
          label: 'تسوية الدين',
          debit: 'النقدية: ${_formatMinor(_saleValueMinor)}',
          credit: 'الطرف: ${_formatMinor(settledAmount)}',
        ),

        // Entry 2: Surplus (if any)
        if (_surplusMinor > 0) ...[
          const SizedBox(height: SpacingTokens.sm),
          _EntryPreview(
            label: 'فائض محتجز للعميل',
            debit: '—',
            credit: 'محتجز: ${_formatMinor(_surplusMinor)}',
            isSurplus: true,
          ),
        ],

        const SizedBox(height: SpacingTokens.md),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.tertiary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'هذا الإجراء لا يمكن التراجع عنه',
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SettlementOption extends StatelessWidget {
  const _SettlementOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = ColorTokens.goldAccent;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? gold.withValues(alpha: 0.1)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? gold : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? gold : scheme.outline,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryPreview extends StatelessWidget {
  const _EntryPreview({
    required this.label,
    required this.debit,
    required this.credit,
    this.isSurplus = false,
  });

  final String label;
  final String debit;
  final String credit;
  final bool isSurplus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isSurplus
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSurplus ? scheme.primary.withValues(alpha: 0.2) : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSurplus ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'مدين: $debit',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'دائن: $credit',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
