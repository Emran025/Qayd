import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:intl/intl.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/widgets/currency_picker_sheet.dart';
import 'package:qayd/application/suggestions/scored_suggestion_dto.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';

class VoucherCreatePage extends StatefulWidget {
  const VoucherCreatePage({super.key, this.initialQrData});

  final Map<String, dynamic>? initialQrData;

  @override
  State<VoucherCreatePage> createState() => _VoucherCreatePageState();
}

class _VoucherCreatePageState extends State<VoucherCreatePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  VoucherType _type = VoucherType.payment;
  DateTime _date = DateTime.now();
  String _currencyCode = PredefinedCurrencies.sar.code;
  AccountSummaryDto? _affected;
  AccountSummaryDto? _counterparty;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideController.value = 1;

    if (widget.initialQrData != null) {
      _applyFromQr(widget.initialQrData!);
    } else {
      _loadBaseCurrency();
    }
  }

  void _applyFromQr(Map<String, dynamic> data) {
    _type = data['type'] as VoucherType;
    _date = data['date'] as DateTime;
    _currencyCode = data['currencyCode'] as String;
    if (data['amountMinorUnits'] != null) {
      _amountController.text =
          formatMinorAmountForField(data['amountMinorUnits'] as int);
    }
    if (data['description'] != null) {
      _descriptionController.text = data['description'] as String;
    }
  }

  Future<void> _loadBaseCurrency() async {
    final res = await InjectionContainer.getBaseCurrencyUseCase();
    if (res.isSuccess && mounted) {
      setState(() => _currencyCode = res.valueOrNull!);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _voucherDate =>
      DateTime(_date.year, _date.month, _date.day);

  void _applyFromSuggestion(VoucherSuggestionsApplied a) {
    if (a.amountMinorUnits != null) {
      _amountController.text =
          formatMinorAmountForField(a.amountMinorUnits!);
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

  Future<void> _pickAffected() async {
    final a = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      excludeAccountId: _counterparty?.id,
    );
    if (a != null) {
      setState(() => _affected = a);
    }
  }

  Future<void> _pickCounterparty() async {
    final a = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      excludeAccountId: _affected?.id,
    );
    if (a != null) {
      setState(() => _counterparty = a);
      if (mounted) {
        await context
            .read<VoucherSuggestionsCubit>()
            .loadForCounterparty(a.id);
      }
    }
  }

  Future<void> _pickCurrency() async {
    final c = await CurrencyPickerSheet.show(context, selectedCode: _currencyCode);
    if (c != null && mounted) {
      setState(() => _currencyCode = c.code);
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_affected == null || _counterparty == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStringsAr.voucherSelectBothAccounts)),
      );
      return;
    }
    if (_affected!.id == _counterparty!.id) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStringsAr.voucherDifferentAccounts)),
      );
      return;
    }
    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || !isReasonableMinorAmount(minor)) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStringsAr.voucherAmountRequired)),
      );
      return;
    }

    final input = CreateVoucherInput(
      type: _type,
      date: _voucherDate,
      amountMinorUnits: minor,
      currencyCode: _currencyCode,
      counterpartyAccountId: _counterparty!.id,
      affectedAccountId: _affected!.id,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    await context.read<VoucherCreateCubit>().submit(input);
  }

  String _typeLabel(VoucherType t) =>
      t == VoucherType.receipt
          ? AppStringsAr.voucherTypeReceipt
          : AppStringsAr.voucherTypePayment;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return MultiBlocListener(
      listeners: [
        BlocListener<VoucherSuggestionsCubit, VoucherSuggestionsState>(
          listenWhen: (p, c) => c is VoucherSuggestionsApplied,
          listener: (context, state) {
            final a = state as VoucherSuggestionsApplied;
            _applyFromSuggestion(a);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.read<VoucherSuggestionsCubit>().loadForCounterparty(
                    _counterparty?.id,
                  );
            });
          },
        ),
        BlocListener<VoucherSuggestionsCubit, VoucherSuggestionsState>(
          listenWhen: (p, c) => c is VoucherSuggestionsError,
          listener: (context, state) {
            final e = state as VoucherSuggestionsError;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.messageAr)),
            );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStringsAr.voucherCreatedDraft),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(state.voucherId);
          }
        },
        builder: (context, state) {
          final submitting = state is VoucherCreateSubmitting;

          return Scaffold(
            appBar: AppBar(
              title: QaydText(
                AppStringsAr.voucherNewTitle,
                slot: QaydTextStyleSlot.titleLarge,
              ),
            ),
            body: AbsorbPointer(
              absorbing: submitting,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  children: [
                    SegmentedButton<VoucherType>(
                      segments: const [
                        ButtonSegment<VoucherType>(
                          value: VoucherType.receipt,
                          label: Text(AppStringsAr.voucherTypeReceipt),
                          icon: Icon(Icons.south_west_rounded, size: 18),
                        ),
                        ButtonSegment<VoucherType>(
                          value: VoucherType.payment,
                          label: Text(AppStringsAr.voucherTypePayment),
                          icon: Icon(Icons.north_east_rounded, size: 18),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) {
                        setState(() => _type = s.first);
                      },
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QaydText(
                        AppStringsAr.voucherDateLabel,
                        slot: QaydTextStyleSlot.bodyMedium,
                      ),
                      subtitle: QaydText(
                        MaterialLocalizations.of(context).formatFullDate(_date),
                        slot: QaydTextStyleSlot.titleSmall,
                      ),
                      trailing: Icon(Icons.calendar_month_rounded, color: gold),
                      onTap: _pickDate,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QaydText(
                        AppStringsAr.voucherCurrencyLabel,
                        slot: QaydTextStyleSlot.bodyMedium,
                      ),
                      subtitle: QaydText(
                        _currencyCode,
                        slot: QaydTextStyleSlot.titleSmall,
                      ),
                      trailing: Icon(Icons.currency_exchange_rounded, color: gold),
                      onTap: _pickCurrency,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QaydText(
                        AppStringsAr.voucherAffectedAccountLabel,
                        slot: QaydTextStyleSlot.labelLarge,
                      ),
                      subtitle: QaydText(
                        _affected?.name ??
                            AppStringsAr.voucherPickAffectedHint,
                        slot: QaydTextStyleSlot.bodyLarge,
                        color: _affected == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                      trailing: Icon(Icons.chevron_left_rounded, color: gold),
                      onTap: _pickAffected,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QaydText(
                        AppStringsAr.voucherCounterpartyLabel,
                        slot: QaydTextStyleSlot.labelLarge,
                      ),
                      subtitle: QaydText(
                        _counterparty?.name ??
                            AppStringsAr.voucherPickCounterpartyHint,
                        slot: QaydTextStyleSlot.bodyLarge,
                        color: _counterparty == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                      trailing: Icon(Icons.chevron_left_rounded, color: gold),
                      onTap: _pickCounterparty,
                    ),
                    if (_counterparty != null) _buildSuggestionsStrip(context),
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
                          const SizedBox(height: SpacingTokens.xl),
                          FilledButton(
                            onPressed: submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(AppStringsAr.voucherSaveDraft),
                          ),
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

  Widget _buildSuggestionsStrip(BuildContext context) {
    return BlocBuilder<VoucherSuggestionsCubit, VoucherSuggestionsState>(
      builder: (context, sug) {
        if (sug is VoucherSuggestionsLoading) {
          return Padding(
            padding: const EdgeInsets.only(top: SpacingTokens.md),
            child: AnimatedOpacity(
              opacity: 0.45,
              duration: const Duration(milliseconds: 280),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        if (sug is! VoucherSuggestionsReady || sug.suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: SpacingTokens.md),
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QaydText(
                  AppStringsAr.smartSuggestionsTitle,
                  slot: QaydTextStyleSlot.titleSmall,
                ),
                const SizedBox(height: SpacingTokens.sm),
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sug.suggestions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: SpacingTokens.sm),
                    itemBuilder: (context, i) {
                      final s = sug.suggestions[i];
                      return _SuggestionCard(
                        suggestion: s,
                        typeLabel: _typeLabel,
                        onAccept: () => context
                            .read<VoucherSuggestionsCubit>()
                            .acceptAndMarkProcessed(s),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.typeLabel,
    required this.onAccept,
  });

  final ScoredSuggestionDto suggestion;
  final String Function(VoucherType) typeLabel;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = suggestion.amountMinorUnits != null
        ? formatMinorAmountForField(suggestion.amountMinorUnits!)
        : '—';
    final dateStr = suggestion.date != null
        ? DateFormat.yMMMd('ar').format(suggestion.date!)
        : '—';
    final typeStr =
        suggestion.type != null ? typeLabel(suggestion.type!) : '—';

    return Material(
      color: ColorTokens.navy800.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: SizedBox(
          width: 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStringsAr.smartSuggestionAmount}: $amt',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${AppStringsAr.smartSuggestionDate}: $dateStr',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${AppStringsAr.smartSuggestionType}: $typeStr',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonal(
                  onPressed: onAccept,
                  child: Text(AppStringsAr.smartSuggestionAccept),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
