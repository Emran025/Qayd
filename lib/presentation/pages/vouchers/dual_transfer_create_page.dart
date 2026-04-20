import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/create_dual_transfer_input.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
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

  DateTime _date = DateTime.now();
  String _currencyCode = PredefinedCurrencies.sar.code;

  AccountSummaryDto? _sender;
  AccountSummaryDto? _receiver;
  AccountSummaryDto? _fund; // auto-detected

  @override
  void initState() {
    super.initState();
    _loadBaseCurrency();
    _autoDetectFund();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
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
        const SnackBar(content: Text('الرجاء اختيار المرسل والمستلم')),
      );
      return;
    }

    if (_fund == null) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('لم يتم العثور على حساب الصندوق تلقائياً')),
      );
      return;
    }

    if (_sender!.id == _receiver!.id) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('لا يمكن أن يكون المرسل والمستلم نفس الطرف')),
      );
      return;
    }

    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || minor <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStringsAr.voucherAmountRequired)),
      );
      return;
    }

    final input = CreateDualTransferInput(
      senderAccountId: _sender!.id,
      receiverAccountId: _receiver!.id,
      fundAccountId: _fund!.id,
      amountMinorUnits: minor,
      currencyCode: _currencyCode,
      date: _date,
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
            const SnackBar(content: Text('تم حفظ التحويل المزدوج بنجاح')),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final submitting = state is VoucherCreateSubmitting;

        return Scaffold(
          appBar: QaydAppBar(
            title: 'تحويل مزدوج مع الصندوق',
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
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: QaydText(
                            'سيتم إنشاء سندين: سند خصم من المرسل وسند إضافة للمستلم.\nالصندوق يتأثر برصيده.',
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
                      'الصندوق (الوسيط)',
                      slot: QaydTextStyleSlot.labelLarge,
                    ),
                    subtitle: QaydText(
                      _fund?.name ?? 'جاري الكشف التلقائي…',
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
                    label: 'المُرْسِل (يُخصم من حسابه)',
                    account: _sender,
                    onTap: () => _pickAccount(0),
                    gold: gold,
                    icon: Icons.south_west_rounded,
                  ),
                  const SizedBox(height: SpacingTokens.sm),

                  // ── Receiver ────────────────────────────────────
                  _buildAccountPicker(
                    label: 'المُسْتلم (يُضاف لحسابه)',
                    account: _receiver,
                    onTap: () => _pickAccount(1),
                    gold: gold,
                    icon: Icons.north_east_rounded,
                  ),
                  const SizedBox(height: SpacingTokens.lg),

                  QaydAmountField(
                    controller: _amountController,
                    label: AppStringsAr.voucherAmountLabel,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: _descriptionController,
                    label: AppStringsAr.voucherDescriptionLabel,
                    maxLines: 2,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: _notesController,
                    label: AppStringsAr.voucherNotesLabel,
                    maxLines: 2,
                  ),
                  const SizedBox(height: SpacingTokens.xl),

                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: ColorTokens.navy950,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: submitting
                        ? const CircularProgressIndicator()
                        : const Text('حفظ التحويل المزدوج'),
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
          AppStringsAr.voucherDateLabel,
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
          AppStringsAr.voucherCurrencyLabel,
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
          account?.name ?? 'اختر الحساب',
          slot: QaydTextStyleSlot.bodyLarge,
          color: account == null
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: gold),
        onTap: onTap,
      );
}
