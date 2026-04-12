import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/cost_center_tag_selector.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';
import 'package:qayd/presentation/widgets/attachment_picker_sheet.dart';
import 'package:qayd/presentation/widgets/currency_picker_sheet.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class InternalVoucherCreatePage extends StatefulWidget {
  final VoucherType? initialType;
  final AccountSummaryDto? initialCategoryAccount;

  const InternalVoucherCreatePage({
    super.key,
    this.initialType,
    this.initialCategoryAccount,
  });

  @override
  State<InternalVoucherCreatePage> createState() =>
      _InternalVoucherCreatePageState();
}

class _InternalVoucherCreatePageState extends State<InternalVoucherCreatePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  VoucherType _type = VoucherType.payment;
  DateTime _date = DateTime.now();
  String _currencyCode = PredefinedCurrencies.sar.code;
  AccountSummaryDto? _fundAccount;
  AccountSummaryDto? _categoryAccount;

  final List<XFile> _pickedImages = [];
  List<CostCenterTagInput> _costCenterTags = [];

  late final AnimationController _slideController;
  late final Animation<Offset> _slideOffset;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    if (widget.initialCategoryAccount != null) {
      _categoryAccount = widget.initialCategoryAccount!;
    }

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.value = 1;

    _loadInitialData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final res = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: true),
    );
    if (res.isSuccess) {
      final accounts = res.valueOrNull!.accounts;
      _fundAccount = accounts
              .where((a) =>
                  a.standardClassificationKind == 'liquidAssets' && a.isRoot)
              .firstOrNull ??
          accounts
              .where((a) => a.standardClassificationKind == 'liquidAssets')
              .firstOrNull;

      final baseRes = await InjectionContainer.getBaseCurrencyUseCase();
      if (baseRes.isSuccess) {
        _currencyCode = baseRes.valueOrNull!;
      }

      // Auto-select category if not provided and only one account exists for this type
      if (_categoryAccount == null) {
        final classification = _type == VoucherType.payment
            ? 'personalExpenses'
            : 'personalRevenues';

        // Check for children first
        final children = accounts
            .where((a) =>
                a.standardClassificationKind == classification && !a.isRoot)
            .toList();

        if (children.length == 1) {
          _categoryAccount = children.first;
        } else if (children.isEmpty) {
          // If no children, check if there's a root (as a fallback or if it's treated as a single account)
          final root = accounts
              .where((a) =>
                  a.standardClassificationKind == classification && a.isRoot)
              .firstOrNull;
          if (root != null) {
            _categoryAccount = root;
          }
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickCurrency() async {
    final c =
        await CurrencyPickerSheet.show(context, selectedCode: _currencyCode);
    if (c != null && mounted) {
      setState(() => _currencyCode = c.code);
    }
  }

  Future<void> _pickCategory() async {
    final classification =
        _type == VoucherType.payment ? 'personalExpenses' : 'personalRevenues';

    final a = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      requireNoRoot: false,
      requireParentClassification: classification,
    );
    if (a != null) {
      setState(() => _categoryAccount = a);
      if (mounted) {
        context.read<VoucherSuggestionsCubit>().loadForCounterparty(a.id);
      }
    }
  }

  Future<void> _pickAttachments() async {
    final files = await AttachmentPickerSheet.show(context);
    if (files != null && files.isNotEmpty && mounted) {
      setState(() => _pickedImages.addAll(files));
    }
  }

  void _applyFromSuggestion(VoucherSuggestionsApplied a) {
    if (a.amountMinorUnits != null) {
      _amountController.text = (a.amountMinorUnits! / 100).toStringAsFixed(2);
    }
    if (a.date != null) {
      _date = DateTime(a.date!.year, a.date!.month, a.date!.day);
    }
    if (a.type != null) {
      _type = a.type!;
    }
    setState(() {});
    _slideController.forward(from: 0);
  }

  Future<void> _submit({required bool confirm}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || minor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsAr.voucherAmountRequired)),
      );
      return;
    }

    if (_fundAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('خطأ: لم يتم العثور على حساب الصندوق الرئيسي.')),
      );
      return;
    }

    if (_categoryAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار حساب المصروف أو الإيراد أولاً.')),
      );
      return;
    }

    final input = CreateVoucherInput(
      type: _type,
      date: _date,
      amountMinorUnits: minor,
      currencyCode: _currencyCode,
      affectedAccountId: _fundAccount!.id,
      counterpartyAccountId: _categoryAccount!.id,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      attachments: _pickedImages,
      costCenterTags: _costCenterTags,
      confirm: confirm,
    );

    await context.read<VoucherCreateCubit>().submit(input);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const QaydScaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final custom = theme.extension<QaydCustomColors>()!;
    final gold = custom.goldAccent;

    return MultiBlocListener(
      listeners: [
        BlocListener<VoucherSuggestionsCubit, VoucherSuggestionsState>(
          listenWhen: (p, c) => c is VoucherSuggestionsApplied,
          listener: (context, state) {
            final a = state as VoucherSuggestionsApplied;
            _applyFromSuggestion(a);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context
                    .read<VoucherSuggestionsCubit>()
                    .loadForCounterparty(_categoryAccount?.id);
              }
            });
          },
        ),
      ],
      child: BlocConsumer<VoucherCreateCubit, VoucherCreateState>(
        listener: (context, state) {
          if (state is VoucherCreateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.messageAr)),
            );
          }
          if (state is VoucherCreateSuccess) {
            final msg = state.stateCode == 'draft'
                ? AppStringsAr.voucherCreatedDraft
                : 'تم تسجيل المعاملة الداخلية بنجاح.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(state.voucherId);
          }
        },
        builder: (context, state) {
          final submitting = state is VoucherCreateSubmitting;

          return QaydScaffold(
            appBar: QaydAppBar(title: AppStringsAr.addInternalVoucherFab),
            body: AbsorbPointer(
              absorbing: submitting,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.lg,
                    vertical: SpacingTokens.md,
                  ),
                  children: [
                    SegmentedButton<VoucherType>(
                      segments: const [
                        ButtonSegment(
                          value: VoucherType.payment,
                          label: Text(AppStringsAr.internalVoucherTypePayment),
                          icon: Icon(Icons.north_east_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: VoucherType.receipt,
                          label: Text(AppStringsAr.internalVoucherTypeReceipt),
                          icon: Icon(Icons.south_west_rounded, size: 18),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() {
                        _type = s.first;
                        _categoryAccount = null;
                      }),
                    ),
                    const SizedBox(height: SpacingTokens.lg),

                    _buildDateTile(gold),
                    const Divider(),
                    _buildCurrencyTile(gold),
                    const Divider(),

                    // // Fixed Fund Account
                    // ListTile(
                    //   contentPadding: EdgeInsets.zero,
                    //   title: QaydText(
                    //     AppStringsAr.internalVoucherFundAccount,
                    //     slot: QaydTextStyleSlot.labelLarge,
                    //     color: scheme.onSurfaceVariant,
                    //   ),
                    //   subtitle: QaydText(_fundAccount?.name ?? '—', slot: QaydTextStyleSlot.bodyLarge),
                    //   trailing: Icon(Icons.lock_outline_rounded, size: 20, color: scheme.outline),
                    // ),
                    const Divider(),

                    // Dynamic Category Account
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QaydText(
                        _type == VoucherType.payment
                            ? 'حساب المصروف'
                            : 'حساب الإيراد',
                        slot: QaydTextStyleSlot.labelLarge,
                        color: scheme.onSurfaceVariant,
                      ),
                      subtitle: QaydText(
                        _categoryAccount?.name ?? 'اختر الحساب المصروف/الإيراد',
                        slot: QaydTextStyleSlot.bodyLarge,
                        color: _categoryAccount == null
                            ? scheme.onSurfaceVariant
                            : null,
                      ),
                      trailing: Icon(Icons.chevron_left_rounded, color: gold),
                      onTap: _pickCategory,
                    ),

                    if (_categoryAccount != null)
                      _buildSuggestionsStrip(context),

                    const SizedBox(height: SpacingTokens.md),

                    SlideTransition(
                      position: _slideOffset,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QaydAmountField(
                            controller: _amountController,
                            label: AppStringsAr.voucherAmountLabel,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: SpacingTokens.md),
                          QaydTextField(
                            controller: _descriptionController,
                            label: AppStringsAr.voucherDescriptionLabel,
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: SpacingTokens.md),

                          CostCenterTagSelector(
                            label: _type == VoucherType.receipt
                                ? AppStringsAr.managementAssetLinkRevenue
                                : AppStringsAr.managementAssetLinkExpense,
                            onChanged: (tags) =>
                                setState(() => _costCenterTags = tags),
                          ),
                          const SizedBox(height: SpacingTokens.md),

                          // Attachments Action
                          OutlinedButton.icon(
                            onPressed: _pickAttachments,
                            icon: Icon(Icons.attach_file_rounded,
                                size: 18, color: gold),
                            label: Text('إرفاق صور',
                                style: TextStyle(color: gold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: gold.withValues(alpha: 0.35)),
                            ),
                          ),

                          // Image thumbnails
                          if (_pickedImages.isNotEmpty) ...[
                            const SizedBox(height: SpacingTokens.sm),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _pickedImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: SpacingTokens.xs),
                                itemBuilder: (context, i) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            RadiusTokens.md),
                                        child: Image.file(
                                          File(_pickedImages[i].path),
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _pickedImages.removeAt(i)),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.65),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: SpacingTokens.xl),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: submitting
                                      ? null
                                      : () => _submit(confirm: false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: gold,
                                    side: BorderSide(color: gold),
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  child: Text(AppStringsAr.voucherSaveDraft),
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.md),
                              Expanded(
                                child: FilledButton(
                                  onPressed: submitting
                                      ? null
                                      : () => _submit(confirm: true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  child: submitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2))
                                      : const Text('تسجيل العملية'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.xxl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTile(Color gold) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: QaydText(AppStringsAr.voucherDateLabel,
          slot: QaydTextStyleSlot.bodyMedium),
      subtitle: QaydText(
        MaterialLocalizations.of(context).formatFullDate(_date),
        slot: QaydTextStyleSlot.titleSmall,
      ),
      trailing: Icon(Icons.calendar_month_rounded, color: gold),
      onTap: _pickDate,
    );
  }

  Widget _buildCurrencyTile(Color gold) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: QaydText(AppStringsAr.voucherCurrencyLabel,
          slot: QaydTextStyleSlot.bodyMedium),
      subtitle: QaydText(_currencyCode, slot: QaydTextStyleSlot.titleSmall),
      trailing: Icon(Icons.currency_exchange_rounded, color: gold),
      onTap: _pickCurrency,
    );
  }

  Widget _buildSuggestionsStrip(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    return BlocBuilder<VoucherSuggestionsCubit, VoucherSuggestionsState>(
      builder: (context, state) {
        if (state is VoucherSuggestionsReady && state.suggestions.isNotEmpty) {
          return SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.suggestions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: SpacingTokens.sm),
              itemBuilder: (context, i) {
                final s = state.suggestions[i];
                final label =
                    s.messageId.startsWith('freq_') ? 'متكرر' : 'مطالبة';
                return ActionChip(
                  label: Text(
                      '$label: ${(s.amountMinorUnits! / 100).toStringAsFixed(0)}'),
                  onPressed: () => context
                      .read<VoucherSuggestionsCubit>()
                      .acceptAndMarkProcessed(s),
                  backgroundColor: gold.withValues(alpha: 0.1),
                  side: BorderSide(color: gold.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill)),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
