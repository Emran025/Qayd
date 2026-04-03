import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/widgets/currency_picker_sheet.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';

class TransferFeesSettingsSection extends StatefulWidget {
  const TransferFeesSettingsSection({super.key});

  @override
  State<TransferFeesSettingsSection> createState() =>
      _TransferFeesSettingsSectionState();
}

class _TransferFeesSettingsSectionState extends State<TransferFeesSettingsSection> {
  final _amountController = TextEditingController();
  bool _enabled = false;
  String? _currencyCode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await InjectionContainer.getActiveTransactionFeeUseCase();
    final baseCurrencyRes = await InjectionContainer.getBaseCurrencyUseCase();
    
    if (mounted) {
      setState(() {
        if (res.isSuccess && res.valueOrNull != null) {
          final fee = res.valueOrNull!;
          _enabled = true;
          _amountController.text = formatMinorAmountForField(fee.amountMinorUnits);
          _currencyCode = fee.currencyCode;
        } else {
          _enabled = false;
          _currencyCode = baseCurrencyRes.valueOrNull;
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_enabled) {
      final minor = parsePositiveMinorUnits(_amountController.text);
      if (minor != null && _currencyCode != null) {
        await InjectionContainer.manageTransactionFeeUseCase.enableFee(
          amountMinorUnits: minor,
          currencyCode: _currencyCode!,
        );
      }
    } else {
      await InjectionContainer.manageTransactionFeeUseCase.disableFee();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الرسوم')),
      );
    }
  }

  Future<void> _pickCurrency() async {
    final c = await CurrencyPickerSheet.show(context, selectedCode: _currencyCode);
    if (c != null) {
      setState(() => _currencyCode = c.code);
      if (_enabled) _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        SwitchListTile(
          title: const Text('تفعيل رسوم التحويل'),
          subtitle: const Text('سيتم إضافة رسوم تلقائية عند إجراء التحويلات.'),
          value: _enabled,
          onChanged: (val) {
            setState(() => _enabled = val);
            _save();
          },
        ),
        if (_enabled) ...[
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                Expanded(
                  child: QaydAmountField(
                    controller: _amountController,
                    label: 'مبلغ الرسوم',
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                InkWell(
                  onTap: _pickCurrency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_currencyCode ?? 'العملة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
