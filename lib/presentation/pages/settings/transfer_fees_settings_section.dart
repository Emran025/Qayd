import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/fee_calculation_type.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';

class TransferFeesSettingsSection extends StatelessWidget {
  const TransferFeesSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeeTypeSection(
          type: TransactionFeeType.dual,
          title: AppStrings.transferFeeBoxMediatedTitle,
          subtitle: AppStrings.transferFeeBoxMediatedSubtitle,
        ),
        const Divider(height: SpacingTokens.xl),
        _FeeTypeSection(
          type: TransactionFeeType.tripartite,
          title: AppStrings.transferFeeTripartiteTitle,
          subtitle: AppStrings.transferFeeTripartiteSubtitle,
        ),
      ],
    );
  }
}

class _FeeTypeSection extends StatefulWidget {
  const _FeeTypeSection({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final TransactionFeeType type;
  final String title;
  final String subtitle;

  @override
  State<_FeeTypeSection> createState() => _FeeTypeSectionState();
}

class _FeeTypeSectionState extends State<_FeeTypeSection> {
  final _valueController = TextEditingController();
  bool _enabled = false;
  FeeCalculationType _calculationType = FeeCalculationType.fixed;
  bool _loading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res =
        await InjectionContainer.getActiveTransactionFeeUseCase(widget.type);

    if (mounted) {
      setState(() {
        if (res.isSuccess && res.valueOrNull != null) {
          final fee = res.valueOrNull!;
          _enabled = true;
          _calculationType = fee.calculationType;
          _valueController.text = _calculationType == FeeCalculationType.fixed
              ? formatMinorAmountForField(fee.value)
              : (fee.value / 100).toString();
        } else {
          _enabled = false;
          _calculationType = FeeCalculationType.fixed;
          _valueController.clear();
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_enabled) {
      final valueRaw = _calculationType == FeeCalculationType.fixed
          ? (parsePositiveMinorUnits(_valueController.text) ?? 0)
          : ((double.tryParse(_valueController.text) ?? 0) * 100).round();

      if (valueRaw < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.transferFeeValidationPositiveValue),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _loading = true);
      final res =
          await InjectionContainer.manageTransactionFeeUseCase.enableFee(
        value: valueRaw,
        calculationType: _calculationType,
        type: widget.type,
      );

      if (res.isFailure) {
        debugPrint('FEE_SAVE_ERROR: ${res.failureOrNull?.messageAr}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${AppStrings.transferFeeSaveFailure}${res.failureOrNull?.messageAr}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }
    } else {
      setState(() => _loading = true);
      final res = await InjectionContainer.manageTransactionFeeUseCase
          .disableFee(widget.type);

      if (res.isFailure) {
        debugPrint('FEE_DISABLE_ERROR: ${res.failureOrNull?.messageAr}');
      }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
          height: 100,
          child: Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: SpacingTokens.sm),
              Text(AppStrings.transferFeeLoading,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          )));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: QaydText(widget.title, slot: QaydTextStyleSlot.titleMedium),
          subtitle:
              QaydText(widget.subtitle, slot: QaydTextStyleSlot.bodySmall),
          value: _enabled,
          onChanged: (val) {
            setState(() {
              _enabled = val;
              if (val && _valueController.text.isEmpty) {
                _isEditing = true;
              }
            });

            if (!val) {
              _save();
            }
          },
        ),
        if (_enabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<FeeCalculationType>(
                    value: _calculationType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.transferFeeCalculationTypeLabel,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: FeeCalculationType.fixed,
                        child: Text(
                          AppStrings.transferFeeFixedOption,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: FeeCalculationType.percentage,
                        child: Text(
                          AppStrings.transferFeePercentageOption,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: _isEditing
                        ? (val) {
                            if (val != null)
                              setState(() => _calculationType = val);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  flex: 3,
                  child: QaydAmountField(
                    controller: _valueController,
                    label: _calculationType == FeeCalculationType.fixed
                        ? AppStrings.transferFeeAmountLabel
                        : AppStrings.transferFeePercentageLabel,
                    enabled: _isEditing,
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
                      const SizedBox(width: SpacingTokens.md),
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
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(AppStrings.transferFeeActionEdit),
                  ),
          ),
        ],
      ],
    );
  }
}
