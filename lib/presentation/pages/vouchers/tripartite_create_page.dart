import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:intl/intl.dart';

import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/widgets/currency_picker_sheet.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/create_tripartite_transfer_input.dart';
import 'package:qayd/di/injection_container.dart';
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

class TripartiteCreatePage extends StatefulWidget {
  const TripartiteCreatePage({super.key, this.initialQrData});

  final Map<String, dynamic>? initialQrData;

  @override
  State<TripartiteCreatePage> createState() => _TripartiteCreatePageState();
}

class _TripartiteCreatePageState extends State<TripartiteCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _date = DateTime.now();
  String _currencyCode = PredefinedCurrencies.sar.code;

  AccountSummaryDto? _source;
  AccountSummaryDto? _dest;
  AccountSummaryDto? _affected;

  @override
  void initState() {
    super.initState();
    if (widget.initialQrData != null) {
      _applyFromQr(widget.initialQrData!);
      if (widget.initialQrData!['currencyCode'] == null) {
        _loadBaseCurrency();
      }
    } else {
      _loadBaseCurrency();
    }
  }

  void _applyFromQr(Map<String, dynamic> data) {
    if (data['date'] is DateTime) {
      _date = data['date'] as DateTime;
    }
    if (data['currencyCode'] is String) {
      _currencyCode = data['currencyCode'] as String;
    }
    if (data['amountMinorUnits'] != null) {
      _amountController.text =
          formatMinorAmountForField(data['amountMinorUnits'] as int);
    }
    if (data['description'] != null) {
      _descriptionController.text = data['description'] as String;
    }

    _loadAccountsFromIds(data['sourceAccountId'], data['destAccountId']);
  }

  Future<void> _loadAccountsFromIds(String? sourceId, String? destId) async {
    if (sourceId != null) {
      final res = await InjectionContainer.listAccountsUseCase
          .call(const ListAccountsInput());
      if (res.isSuccess) {
        final accounts = res.valueOrNull?.accounts;
        final match = accounts?.where((a) => a.id == sourceId).firstOrNull;
        if (match != null) setState(() => _source = match);
      }
    }
    if (destId != null) {
      final res = await InjectionContainer.listAccountsUseCase
          .call(const ListAccountsInput());
      if (res.isSuccess) {
        final accounts = res.valueOrNull?.accounts;
        final match = accounts?.where((a) => a.id == destId).firstOrNull;
        if (match != null) setState(() => _dest = match);
      }
    }
  }

  Future<void> _loadBaseCurrency() async {
    final res = await InjectionContainer.getBaseCurrencyUseCase();
    if (res.isSuccess && mounted) {
      setState(() => _currencyCode = res.valueOrNull!);
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
    final excludedClasses = [
      StandardAccountClassificationKind.liquidAssets.name,
      StandardAccountClassificationKind.fixedDepreciableAssets.name,
      StandardAccountClassificationKind.fixedProfitableAssets.name,
      StandardAccountClassificationKind.clearingRemittances.name,
      StandardAccountClassificationKind.remittanceFees.name,
    ];
    final allowedClasses = StandardAccountClassificationKind.values
        .map((k) => k.name)
        .where((n) => !excludedClasses.contains(n))
        .toList();
    final res = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      requireNoRoot: true,
      allowedClassifications: allowedClasses,
    );
    if (res != null) {
      setState(() {
        if (fieldIndex == 0) _source = res;
        if (fieldIndex == 1) _affected = res;
        if (fieldIndex == 2) _dest = res;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);

    if (_affected == null) {
      final accountsRes = await InjectionContainer.listAccountsUseCase
          .call(const ListAccountsInput());
      if (accountsRes.isSuccess) {
        final accounts = accountsRes.valueOrNull?.accounts ?? [];
        if (accounts
                .where((a) => a.name == AppStrings.clearingAccountName)
                .firstOrNull ==
            null) {
          messenger.showSnackBar(
            SnackBar(content: Text(AppStrings.tripartiteNoClearingAccount)),
          );
          return;
        }
        _affected = accounts
            .where((a) => a.name == AppStrings.clearingAccountName)
            .firstOrNull;
      }
    }

    if (_source == null || _affected == null || _dest == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.tripartiteSelectAccounts)),
      );
      return;
    }

    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || minor <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.voucherAmountRequired)),
      );
      return;
    }

    final input = CreateTripartiteTransferInput(
      sourceAccountId: _source!.id,
      affectedAccountId: _affected!.id,
      destinationAccountId: _dest!.id,
      amountMinorUnits: minor,
      currencyCode: _currencyCode,
      date: _date,
      description: _descriptionController.text.trim(),
    );

    await context.read<VoucherCreateCubit>().submitTripartite(input);
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return BlocConsumer<VoucherCreateCubit, VoucherCreateState>(
      listener: (context, state) {
        if (state is VoucherCreateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure.messageAr)),
          );
        }
        if (state is VoucherCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.tripartiteDraftSaved)),
          );
          Navigator.of(context).pop();
        }
        if (state is VoucherCreateTripartiteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.tripartiteCreatedSuccess)),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final submitting = state is VoucherCreateSubmitting;

        return Scaffold(
          appBar: QaydAppBar(
            title: AppStrings.tripartiteNewTitle,
          ),
          body: AbsorbPointer(
            absorbing: submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                children: [
                  _buildDateTile(gold),
                  const Divider(),
                  _buildCurrencyTile(gold),
                  const Divider(),
                  _buildAccountPicker(
                    label: AppStrings.tripartiteSourceLabel,
                    account: _source,
                    onTap: () => _pickAccount(0),
                    gold: gold,
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  _buildAccountPicker(
                    label: AppStrings.tripartiteDestinationLabel,
                    account: _dest,
                    onTap: () => _pickAccount(2),
                    gold: gold,
                  ),
                  SizedBox(height: SpacingTokens.lg),
                  QaydAmountField(
                    controller: _amountController,
                    label: AppStrings.voucherAmountLabel,
                  ),
                  SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: _descriptionController,
                    label: AppStrings.voucherDescriptionLabel,
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
                        : Text(AppStrings.voucherSaveDraft),
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
          DateFormat.yMMMd('ar').format(_date),
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
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: QaydText(
          label,
          slot: QaydTextStyleSlot.labelLarge,
        ),
        subtitle: QaydText(
          account?.name ?? AppStrings.tripartiteSelectAccountHint,
          slot: QaydTextStyleSlot.bodyLarge,
          color: account == null
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: gold),
        onTap: onTap,
      );
}
