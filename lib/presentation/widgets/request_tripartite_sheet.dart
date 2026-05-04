import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/vouchers/create_tripartite_request_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';

class RequestTripartiteSheet extends StatefulWidget {
  const RequestTripartiteSheet({
    super.key,
    required this.destinationAccountId,
    required this.destinationName,
  });

  final String destinationAccountId;
  final String destinationName;

  static Future<void> show(
    BuildContext context, {
    required String destinationAccountId,
    required String destinationName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestTripartiteSheet(
        destinationAccountId: destinationAccountId,
        destinationName: destinationName,
      ),
    );
  }

  @override
  State<RequestTripartiteSheet> createState() => _RequestTripartiteSheetState();
}

class _RequestTripartiteSheetState extends State<RequestTripartiteSheet> {
  final _amountController = TextEditingController();
  AccountSummaryDto? _mediator;
  bool _submitting = false;

  Future<void> _pickMediator() async {
    final res = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      requireNoRoot: true,
      allowedClassifications: const ['receivables', 'payables'],
    );
    if (res != null) setState(() => _mediator = res);
  }

  Future<void> _submit() async {
    if (_mediator == null) return;
    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || minor <= 0) return;

    setState(() => _submitting = true);

    try {
      final useCase = CreateTripartiteRequestUseCase(
        notificationRepo: InjectionContainer.notificationMessageRepository,
        syncEventDispatcher: InjectionContainer.syncEventDispatcher,
      );

      final r = await useCase.call(
        CreateTripartiteRequestInput(
          mediatorAccountId: _mediator!.id,
          destinationAccountId: widget.destinationAccountId,
          amountMinorUnits: minor,
          currencyCode: PredefinedCurrencies.sar.code,
        ),
      );

      if (mounted) {
        r.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.messageAr)),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppStrings.theTransferRequestHas)),
            );
            Navigator.pop(context);
          },
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RadiusTokens.lg),
        ),
      ),
      padding: EdgeInsets.only(
        left: SpacingTokens.lg,
        right: SpacingTokens.lg,
        top: SpacingTokens.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + SpacingTokens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: gold),
              SizedBox(width: SpacingTokens.md),
              Expanded(
                child: QaydText(
                  AppStrings.tripartiteRequestFor(widget.destinationName),
                  slot: QaydTextStyleSlot.titleLarge,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(AppStrings.selectTheApprovedFinancial),
            subtitle: Text(_mediator?.name ?? AppStrings.clickToChooseThe),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: gold),
            onTap: _pickMediator,
          ),
          SizedBox(height: SpacingTokens.md),
          QaydAmountField(
            controller: _amountController,
            label: AppStrings.voucherAmountLabel,
          ),
          SizedBox(height: SpacingTokens.xl),
          FilledButton(
            onPressed: (_mediator != null && !_submitting) ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: ColorTokens.navy950,
              minimumSize: const Size.fromHeight(56),
            ),
            child: _submitting
                ? const CircularProgressIndicator()
                : Text(AppStrings.submitTheRequest),
          ),
        ],
      ),
    );
  }
}
