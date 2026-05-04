import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
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

class _TransferFeesSettingsSectionState
    extends State<TransferFeesSettingsSection> {
  final _amountController = TextEditingController();
  bool _enabled = false;
  String? _currencyCode;
  bool _loading = true;

  bool _isEditing = false;

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
          _amountController.text =
              formatMinorAmountForField(fee.amountMinorUnits);
          _currencyCode = fee.currencyCode;
        } else {
          _enabled = false;
          _currencyCode = baseCurrencyRes.valueOrNull;
          _amountController.clear();
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_enabled) {
      final minor = parsePositiveMinorUnits(_amountController.text) ?? 0;
      if (minor < 0 || _currencyCode == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.transferFeeErrorInvalidAmount),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _loading = true);
      await InjectionContainer.manageTransactionFeeUseCase.enableFee(
        amountMinorUnits: minor,
        currencyCode: _currencyCode!,
      );
    } else {
      setState(() => _loading = true);
      await InjectionContainer.manageTransactionFeeUseCase.disableFee();
    }

    await _load();
    setState(() {
      _isEditing = false;
      _loading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.transferFeeSaveSuccess)),
      );
    }
  }

  Future<void> _pickCurrency() async {
    if (!_isEditing) return;

    final c =
        await CurrencyPickerSheet.show(context, selectedCode: _currencyCode);
    if (c != null) {
      setState(() => _currencyCode = c.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(AppStrings.transferFeeToggleTitle),
          subtitle: Text(AppStrings.transferFeeToggleSubtitle),
          value: _enabled,
          onChanged: (val) {
            setState(() {
              _enabled = val;
              if (val && _amountController.text.isEmpty) {
                _isEditing =
                    true; // Force editing if enabling for the first time
              }
            });

            if (!val) {
              _save(); // Immediate disable
            }
          },
        ),
        if (_enabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
            child: Row(
              children: [
                Expanded(
                  child: QaydAmountField(
                    controller: _amountController,
                    label: AppStrings.transferFeeAmountLabel,
                    enabled: _isEditing,
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                InkWell(
                  onTap: _isEditing ? _pickCurrency : null,
                  child: Opacity(
                    opacity: _isEditing ? 1.0 : 0.6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_currencyCode ?? AppStrings.currencyLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: _isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _load();
                          },
                          child: Text(AppStrings.actionCancel),
                        ),
                      ),
                      SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          child: Text(AppStrings.transferFeeActionSave),
                        ),
                      ),
                    ],
                  )
                : OutlinedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: Icon(Icons.edit_outlined, size: 18),
                    label: Text(AppStrings.transferFeeActionEdit),
                  ),
          ),
        ],
      ],
    );
  }
}
