import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/create_dual_transfer_input.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/fee_calculation_type.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';
import 'package:qayd/presentation/widgets/currency_picker_sheet.dart';
import 'package:qayd/core/result/result.dart';

/// Page for creating a dual transfer (two standard vouchers through the fund).
///
/// The user selects:
/// - Sender account (external party — debit)
/// - Receiver account (external party — credit)
/// - The fund/cashbox is auto-detected (liquidAssets)
/// - Amount, currency, date, description
class DualTransferCreatePage extends StatefulWidget {
  const DualTransferCreatePage({super.key});

  @override
  State<DualTransferCreatePage> createState() => _DualTransferCreatePageState();
}

class _DualTransferCreatePageState extends State<DualTransferCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _feeController = TextEditingController();

  DateTime _date = DateTime.now();
  String _currencyCode = PredefinedCurrencies.sar.code;
  bool _applyFee = false;
  FeeCalculationType _feeCalculationType = FeeCalculationType.fixed;
  int _feeValue = 0; // The raw value from settings

  AccountSummaryDto? _sender;
  AccountSummaryDto? _receiver;
  AccountSummaryDto? _fund; // auto-detected

  bool _isFeeManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadBaseCurrency();
    _autoDetectFund();
    _loadDefaultFee();
  }

  void _onAmountChanged() {
    if (_applyFee &&
        !_isFeeManuallyEdited &&
        _feeCalculationType == FeeCalculationType.percentage) {
      final amountMinor = parsePositiveMinorUnits(_amountController.text) ?? 0;
      final calculatedFeeMinor = (amountMinor * (_feeValue / 10000)).round();
      setState(() {
        _feeController.text = formatMinorAmountForField(calculatedFeeMinor);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultFee() async {
    final res = await InjectionContainer.getActiveTransactionFeeUseCase(
        TransactionFeeType.dual);
    if (res.isSuccess && res.valueOrNull != null && mounted) {
      final fee = res.valueOrNull!;
      setState(() {
        _applyFee = true;
        _feeCalculationType = fee.calculationType;
        _feeValue = fee.value;
        _isFeeManuallyEdited = false;

        if (_feeCalculationType == FeeCalculationType.fixed) {
          _feeController.text = formatMinorAmountForField(_feeValue);
        } else {
          // Calculation will happen via listener when amount is entered
          _onAmountChanged();
        }
      });
    }
  }

  Future<void> _loadBaseCurrency() async {
    final res = await InjectionContainer.getBaseCurrencyUseCase();
    if (res.isSuccess && mounted) {
      setState(() => _currencyCode = res.valueOrNull!);
    }
  }

  Future<void> _autoDetectFund() async {
    final res = await InjectionContainer.listAccountsUseCase
        .call(const ListAccountsInput());
    if (res.isSuccess && mounted) {
      final accounts = res.valueOrNull?.accounts ?? [];
      final liquidAssets = accounts
          .where((a) => a.standardClassificationKind == 'liquidAssets')
          .firstOrNull;
      if (liquidAssets != null) {
        setState(() => _fund = liquidAssets);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickCurrency() async {
    final c =
        await CurrencyPickerSheet.show(context, selectedCode: _currencyCode);
    if (c != null) setState(() => _currencyCode = c.code);
  }

  Future<void> _pickAccount(int fieldIndex) async {
    final res = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      requireNoRoot: true,
      allowedClassifications: const ['receivables', 'payables'],
    );
    if (res != null) {
      setState(() {
        if (fieldIndex == 0) _sender = res;
        if (fieldIndex == 1) _receiver = res;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);

    if (_sender == null || _receiver == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseSelectASender)),
      );
      return;
    }

    if (_fund == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.theFundAccountWas)),
      );
      return;
    }

    if (_sender!.id == _receiver!.id) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.theSenderAndRecipient1)),
      );
      return;
    }

    final amountMinor = parsePositiveMinorUnits(_amountController.text);
    if (amountMinor == null || amountMinor <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.voucherAmountRequired)),
      );
      return;
    }

    int calculatedFeeMinor = 0;
    if (_applyFee) {
      calculatedFeeMinor = parsePositiveMinorUnits(_feeController.text) ?? 0;
    }

    final input = CreateDualTransferInput(
      senderAccountId: _sender!.id,
      receiverAccountId: _receiver!.id,
      fundAccountId: _fund!.id,
      amountMinorUnits: amountMinor,
      currencyCode: _currencyCode,
      date: _date,
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      feeAmountMinorUnits: _applyFee ? calculatedFeeMinor : null,
    );

    await context.read<VoucherCreateCubit>().submitDualTransfer(input);
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<VoucherCreateCubit, VoucherCreateState>(
      listener: (context, state) {
        if (state is VoucherCreateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure.messageAr)),
          );
        }
        if (state is VoucherCreateDualSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.theDoubleConversionWas)),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final submitting = state is VoucherCreateSubmitting;

        return Scaffold(
          appBar: QaydAppBar(
            title: AppStrings.doubleConversionWithBox,
          ),
          body: AbsorbPointer(
            absorbing: submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                children: [
                  // ── Info banner ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: ColorTokens.debitBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorTokens.debitBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 20, color: ColorTokens.debitBlue),
                        SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: QaydText(
                            AppStrings.twoVouchersWillBe,
                            slot: QaydTextStyleSlot.bodySmall,
                            color: ColorTokens.debitBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildDateTile(gold),
                  const Divider(),
                  _buildCurrencyTile(gold),
                  const Divider(),

                  // ── Fund (auto-detected, read-only) ─────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: QaydText(
                      AppStrings.fundBroker,
                      slot: QaydTextStyleSlot.labelLarge,
                    ),
                    subtitle: QaydText(
                      _fund?.name ?? AppStrings.automaticallyDetecting,
                      slot: QaydTextStyleSlot.bodyLarge,
                      color: _fund == null ? scheme.onSurfaceVariant : null,
                    ),
                    trailing: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: gold,
                      size: 20,
                    ),
                  ),
                  const Divider(),

                  // ── Sender ──────────────────────────────────────
                  _buildAccountPicker(
                    label: AppStrings.senderDeductedFromHis,
                    account: _sender,
                    onTap: () => _pickAccount(0),
                    gold: gold,
                    icon: Icons.south_west_rounded,
                  ),
                  SizedBox(height: SpacingTokens.sm),

                  // ── Receiver ────────────────────────────────────
                  _buildAccountPicker(
                    label: AppStrings.recipientCreditedToHis,
                    account: _receiver,
                    onTap: () => _pickAccount(1),
                    gold: gold,
                    icon: Icons.north_east_rounded,
                  ),
                  SizedBox(height: SpacingTokens.lg),

                  QaydAmountField(
                    controller: _amountController,
                    label: AppStrings.voucherAmountLabel,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: SpacingTokens.md),

                  // ── Fees Section ──────────────────────────────────
                  _buildFeesSection(gold, scheme),
                  SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: _descriptionController,
                    label: AppStrings.voucherDescriptionLabel,
                    maxLines: 2,
                  ),
                  SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: _notesController,
                    label: AppStrings.voucherNotesLabel,
                    maxLines: 2,
                  ),
                  SizedBox(height: SpacingTokens.xl),

                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: ColorTokens.navy950,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: submitting
                        ? const CircularProgressIndicator()
                        : Text(AppStrings.saveTheDoubleConversion),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTile(Color gold) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: QaydText(
          AppStrings.voucherDateLabel,
          slot: QaydTextStyleSlot.labelLarge,
        ),
        subtitle: QaydText(
          DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
              .format(_date),
          slot: QaydTextStyleSlot.bodyLarge,
        ),
        trailing: Icon(Icons.calendar_today_rounded, color: gold, size: 20),
        onTap: _pickDate,
      );

  Widget _buildCurrencyTile(Color gold) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: QaydText(
          AppStrings.voucherCurrencyLabel,
          slot: QaydTextStyleSlot.labelLarge,
        ),
        subtitle: QaydText(
          _currencyCode,
          slot: QaydTextStyleSlot.bodyLarge,
        ),
        trailing: Icon(Icons.currency_exchange_rounded, color: gold, size: 20),
        onTap: _pickCurrency,
      );

  Widget _buildAccountPicker({
    required String label,
    required AccountSummaryDto? account,
    required VoidCallback onTap,
    required Color gold,
    IconData icon = Icons.chevron_left_rounded,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: gold, size: 20),
        title: QaydText(
          label,
          slot: QaydTextStyleSlot.labelLarge,
        ),
        subtitle: QaydText(
          account?.name ?? AppStrings.chooseAccount,
          slot: QaydTextStyleSlot.bodyLarge,
          color: account == null
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: gold),
        onTap: onTap,
      );

  Widget _buildFeesSection(Color gold, ColorScheme scheme) {
    final amountMinor = parsePositiveMinorUnits(_amountController.text) ?? 0;
    final calculatedFeeMinor =
        _applyFee ? (parsePositiveMinorUnits(_feeController.text) ?? 0) : 0;

    final netMinor = amountMinor - calculatedFeeMinor;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.percent_rounded, color: gold, size: 20),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: QaydText(
                  AppStrings.transferFeesLabel,
                  slot: QaydTextStyleSlot.labelLarge,
                ),
              ),
              Switch.adaptive(
                value: _applyFee,
                onChanged: (val) => setState(() => _applyFee = val),
                activeColor: gold,
              ),
            ],
          ),
          if (_applyFee) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: QaydText(
                AppStrings.transferFeeAmountLabel,
                slot: QaydTextStyleSlot.bodyMedium,
                color: scheme.onSurfaceVariant,
              ),
              subtitle: QaydText(
                _feeController.text.isEmpty ? '0.00' : _feeController.text,
                slot: QaydTextStyleSlot.headlineSmall,
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit_note_rounded, color: gold),
                onPressed: _showEditFeeDialog,
              ),
            ),
            if (amountMinor > 0) ...[
              const SizedBox(height: SpacingTokens.xs),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QaydText(
                      AppStrings.transferFeeNetToRecipient,
                      slot: QaydTextStyleSlot.bodySmall,
                      color: scheme.onSurfaceVariant,
                    ),
                    QaydText(
                      formatMinorAmountForField(netMinor),
                      slot: QaydTextStyleSlot.labelLarge,
                      color: gold,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _showEditFeeDialog() async {
    final controller = TextEditingController(text: _feeController.text);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => QaydDialog(
        title: AppStrings.transferFeeEditAmountTitle,
        content: QaydAmountField(
          controller: controller,
          label: AppStrings.transferFeeAmountLabel,
        ),
        secondaryActionLabel: AppStrings.actionCancel,
        primaryActionLabel: AppStrings.actionConfirm,
        onPrimaryAction: () {
          setState(() => _isFeeManuallyEdited = true);
          Navigator.pop(ctx, controller.text);
        },
      ),
    );

    if (res != null) {
      setState(() => _feeController.text = res);
    }
  }
}
