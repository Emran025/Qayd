import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
// import 'package:intl/intl.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/widgets/currency_picker_sheet.dart';
// import 'package:qayd/application/suggestions/scored_suggestion_dto.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/presentation/widgets/attachment_picker_sheet.dart';
import 'package:qayd/presentation/widgets/collateral_entry_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_amount_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/amount_parser.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/cost_center_tag_selector.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

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

  // Hidden tripartite fields from QR
  String? _hiddenTransferGroupId;
  String? _hiddenTripartiteRole;
  String? _hiddenLinkedPartyId;
  bool _hiddenIsContingent = false;

  bool _canPickAffectedAccount = true;

  // Signature fields from QR
  String? _qrSenderSignatureHex;
  String? _qrSenderPublicKeyHex;
  String? _qrReceiverSignatureHex;
  String? _qrReceiverPublicKeyHex;
  bool _isQrSignatureValid = false;

  /// Phone of the QR issuer (Party A) — frozen from QR and passed to use case
  /// so [canonicalSenderPhone] is correctly set on the created voucher.
  String? _qrSignerPhone;

  // Attachment & collateral state
  final List<XFile> _pickedImages = [];
  CollateralInput? _collateralInput;
  List<CostCenterTagInput> _costCenterTags = [];

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
    _loadDefaultFundAccount();

    _amountController.addListener(_updateSignatureValidity);
  }

  void _updateSignatureValidity() {
    if (_qrSenderSignatureHex == null || widget.initialQrData == null) return;

    final currentMinor = parsePositiveMinorUnits(_amountController.text) ?? 0;
    final qrMinor = widget.initialQrData!['amountMinorUnits'] as int? ?? 0;

    final amountMatches = currentMinor == qrMinor;
    final currencyMatches =
        _currencyCode == widget.initialQrData!['currencyCode'];
    final dateMatches =
        _date.year == (widget.initialQrData!['date'] as DateTime).year &&
            _date.month == (widget.initialQrData!['date'] as DateTime).month &&
            _date.day == (widget.initialQrData!['date'] as DateTime).day;

    final isValid = amountMatches && currencyMatches && dateMatches;

    if (isValid != _isQrSignatureValid) {
      setState(() {
        _isQrSignatureValid = isValid;
      });
    }
  }

  Future<void> _loadDefaultFundAccount() async {
    final res = await InjectionContainer.listAccountsUseCase.call(
      const ListAccountsInput(activeOnly: true),
    );
    if (res.isSuccess && mounted) {
      final accounts = res.valueOrNull!.accounts;
      final roots = accounts.where(
          (a) => a.standardClassificationKind == 'liquidAssets' && a.isRoot);
      final fund = roots.isNotEmpty
          ? roots.first
          : accounts
                  .where((a) => a.standardClassificationKind == 'liquidAssets')
                  .firstOrNull ??
              accounts.firstOrNull;

      final selectableCount = accounts
          .where((a) =>
              a.standardClassificationKind == 'liquidAssets' && !a.isRoot)
          .length;

      setState(() {
        if (fund != null && _affected == null) {
          _affected = fund;
        }
        _canPickAffectedAccount = selectableCount > 1;
      });
    }
  }

  void _applyFromQr(Map<String, dynamic> data) {
    if (data['type'] != null) {
      _type = data['type'] as VoucherType;
    }
    if (data['date'] != null) {
      _date = data['date'] as DateTime;
    }
    if (data['currencyCode'] != null) {
      _currencyCode = data['currencyCode'] as String;
    }
    if (data['amountMinorUnits'] != null) {
      _amountController.text =
          formatMinorAmountForField(data['amountMinorUnits'] as int);
    }
    if (data['description'] != null) {
      _descriptionController.text = data['description'] as String;
    }
    if (data['notes'] != null) {
      // If we have notes in QR, we can append to description or keep as hidden notes
      // but for now let's just make sure they are available if needed.
    }
    if (data['collateralDescription'] != null) {
      _collateralInput = CollateralInput(
        description: data['collateralDescription'] as String,
        estimatedValueMinor: data['collateralAmountMinorUnits'] as int? ?? 0,
        expiryDate: data['collateralExpiryDate'] as DateTime?,
        imagePaths: [], // Media is explicitly excluded
      );
    }
    if (data['counterpartyAccountId'] != null) {
      final accId = data['counterpartyAccountId'].toString();
      _loadAccountSummaryForCounterparty(accId);
    }
    if (data['transferGroupId'] != null) {
      _hiddenTransferGroupId = data['transferGroupId'] as String?;
      _hiddenTripartiteRole = data['tripartiteRole'] as String?;
      _hiddenLinkedPartyId = data['linkedPartyId'] as String?;
      _hiddenIsContingent = data['isContingent'] as bool? ?? false;

      // If we received an intermediary payment, this receipt is the final act.
      // We flip the role to receipt to indicate we are receiving the payment.
      if (_hiddenTripartiteRole == 'intermediaryPayment') {
        _hiddenTripartiteRole = 'intermediaryReceipt';
      } else if (_hiddenTripartiteRole == 'intermediaryReceipt') {
        _hiddenTripartiteRole = 'intermediaryPayment';
      }
    }

    if (data['signatureHex'] != null) {
      _qrSenderSignatureHex = data['signatureHex'] as String?;
      _qrSenderPublicKeyHex = data['signerPublicKeyHex'] as String?;
      _isQrSignatureValid = true;
    }
    // Capture the QR issuer's phone (Party A = sender) for canonical payload.
    if (data['signerPhone'] != null) {
      _qrSignerPhone = data['signerPhone'] as String?;
    }
    if (data['receiverSignatureHex'] != null) {
      _qrReceiverSignatureHex = data['receiverSignatureHex'] as String?;
      _qrReceiverPublicKeyHex = data['receiverPublicKeyHex'] as String?;
    }
  }

  Future<void> _loadAccountSummaryForCounterparty(String id) async {
    final res = await InjectionContainer.listAccountsUseCase.call(
      const ListAccountsInput(activeOnly: true),
    );
    if (res.isSuccess && mounted) {
      final accounts = res.valueOrNull!.accounts;
      final acc = accounts.where((a) => a.id == id).firstOrNull;
      if (acc != null) {
        setState(() => _counterparty = acc);
        await context.read<VoucherSuggestionsCubit>().loadForCounterparty(id);
      }
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
    _amountController.removeListener(_updateSignatureValidity);
    _slideController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _voucherDate => DateTime(_date.year, _date.month, _date.day);

  void _applyFromSuggestion(VoucherSuggestionsApplied a) {
    if (a.amountMinorUnits != null) {
      _amountController.text = formatMinorAmountForField(a.amountMinorUnits!);
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
      _updateSignatureValidity();
    }
  }

  Future<void> _pickCounterparty() async {
    // Exclude classifications that don't make sense as a counterparty (like Cash or Fixed Assets)
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

    final a = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      excludeAccountId: _affected?.id,
      requireNoRoot: true,
      allowedClassifications: allowedClasses,
    );
    if (a != null) {
      setState(() => _counterparty = a);
      if (mounted) {
        await context.read<VoucherSuggestionsCubit>().loadForCounterparty(a.id);
      }
      // Auto-populate cost centers from counterparty account defaults
      await _loadDefaultCostCentersForAccount(a.id);
    }
  }

  Future<void> _pickAffectedAccount() async {
    final allowedClasses = ['liquidAssets'];

    final a = await showAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      excludeAccountId: _counterparty?.id,
      requireNoRoot: true,
      allowedClassifications: allowedClasses,
    );
    if (a != null) {
      setState(() => _affected = a);
      // Auto-populate cost centers from account defaults
      await _loadDefaultCostCentersForAccount(a.id);
    }
  }

  Future<void> _pickCurrency() async {
    final c =
        await CurrencyPickerSheet.show(context, selectedCode: _currencyCode);
    if (c != null && mounted) {
      setState(() => _currencyCode = c.code);
      _updateSignatureValidity();
    }
  }

  /// Loads the account's default cost centers and pre-populates
  /// [_costCenterTags] so [CostCenterTagSelector] shows them automatically.
  Future<void> _loadDefaultCostCentersForAccount(String accountId) async {
    final res = await InjectionContainer.manageAccountDefaultCostCentersUseCase
        .list(AccountId(accountId));
    if (!res.isSuccess || !mounted) return;
    final defaults = res.valueOrNull!;
    if (defaults.isEmpty) return;
    final tags = defaults
        .map(
          (d) => CostCenterTagInput(
            costCenterId: d.costCenterId,
            dimensionIds: d.dimensionIds,
          ),
        )
        .toList();
    setState(() => _costCenterTags = tags);
  }

  Future<void> _pickAttachments() async {
    final files = await AttachmentPickerSheet.show(context);
    if (files != null && files.isNotEmpty && mounted) {
      setState(() => _pickedImages.addAll(files));
    }
  }

  Future<void> _addCollateral() async {
    final input = await CollateralEntrySheet.show(
      context,
      currencyCode: _currencyCode,
    );
    if (input != null && mounted) {
      setState(() => _collateralInput = input);
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || !isReasonableMinorAmount(minor)) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.voucherAmountRequired)),
      );
      return;
    }

    await _submitStandard(messenger, minor, confirm: false);
  }

  Future<void> _submitConfirm() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final minor = parsePositiveMinorUnits(_amountController.text);
    if (minor == null || !isReasonableMinorAmount(minor)) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.voucherAmountRequired)),
      );
      return;
    }

    await _submitStandard(messenger, minor, confirm: true);
  }

  Future<void> _submitStandard(
    ScaffoldMessengerState messenger,
    int minor, {
    required bool confirm,
  }) async {
    if (_affected == null || _counterparty == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.voucherSelectBothAccounts)),
      );
      return;
    }
    if (_affected!.id == _counterparty!.id) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.voucherDifferentAccounts)),
      );
      return;
    }

    final initialCounterparty =
        widget.initialQrData?['counterpartyAccountId'] as String?;
    final initialDate = widget.initialQrData?['date'] as DateTime?;
    final isEdit = widget.initialQrData?['originVoucherId'] != null ||
        widget.initialQrData?['editingVoucherId'] != null;

    if (isEdit && initialCounterparty != null && initialDate != null) {
      final initialDateMidnight =
          DateTime(initialDate.year, initialDate.month, initialDate.day);
      if (_counterparty!.id != initialCounterparty ||
          _voucherDate.compareTo(initialDateMidnight) != 0) {
        final proceed = await QaydDialog.show<bool>(
          context: context,
          icon: Icons.warning_amber_rounded,
          title: AppStrings.warningImportant,
          content: AppStrings.voucherEditDateOrPartyWarning,
          secondaryActionLabel: AppStrings.templateEditCancel,
          onSecondaryAction: () => Navigator.pop(context, false),
          primaryActionLabel: AppStrings.actionProceedAndConfirm,
          onPrimaryAction: () => Navigator.pop(context, true),
        );

        if (proceed != true) return;
      }
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
      transferGroupId: _hiddenTransferGroupId,
      tripartiteRole: _hiddenTripartiteRole,
      linkedPartyId: _hiddenLinkedPartyId,
      isContingent: _hiddenIsContingent,
      attachments: _pickedImages,
      confirm: confirm,
      originVoucherId: widget.initialQrData?['originVoucherId'] as String?,
      editingVoucherId: widget.initialQrData?['editingVoucherId'] as String?,
      costCenterTags: _costCenterTags,
      collateral: _collateralInput == null
          ? null
          : CreateCollateralInput(
              description: _collateralInput!.description,
              estimatedValueMinor: _collateralInput!.estimatedValueMinor,
              expiryDate: _collateralInput!.expiryDate,
              imagePaths: _collateralInput!.imagePaths,
            ),
      senderSignatureHex: _isQrSignatureValid ? _qrSenderSignatureHex : null,
      senderPublicKeyHex: _isQrSignatureValid ? _qrSenderPublicKeyHex : null,
      receiverSignatureHex: _qrReceiverSignatureHex,
      receiverPublicKeyHex: _qrReceiverPublicKeyHex,
      // Pass QR issuer phone as canonical sender; receiver phone is resolved
      // from LicenseVault inside CreateVoucherUseCase / ConfirmVoucherUseCase.
      qrSignerPhone: _isQrSignatureValid ? _qrSignerPhone : null,
    );

    await context.read<VoucherCreateCubit>().submit(input);
  }

  // String _typeLabel(VoucherType t) => t == VoucherType.receipt
  //     ? AppStrings.voucherTypeReceipt
  //     : AppStrings.voucherTypePayment;

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
            final msg = state.stateCode == 'draft'
                ? AppStrings.voucherCreatedDraft
                : AppStrings.voucherConfirmedAndSentSuccess;
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

          return Scaffold(
            appBar: QaydAppBar(title: AppStrings.voucherNewTitle),
            body: AbsorbPointer(
              absorbing: submitting,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(SpacingTokens.lg),
                  children: [
                    // ── Standard mode ─────────────────────────────────
                    SegmentedButton<VoucherType>(
                      segments: [
                        ButtonSegment<VoucherType>(
                          value: VoucherType.receipt,
                          label: Text(AppStrings.voucherTypeReceipt),
                          icon: Icon(Icons.south_west_rounded, size: 18),
                        ),
                        ButtonSegment<VoucherType>(
                          value: VoucherType.payment,
                          label: Text(AppStrings.voucherTypePayment),
                          icon: Icon(Icons.north_east_rounded, size: 18),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) {
                        setState(() => _type = s.first);
                      },
                    ),
                    SizedBox(height: SpacingTokens.md),
                    _buildDateTile(gold),
                    const Divider(),
                    _buildCurrencyTile(gold),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QaydText(
                        _type == VoucherType.payment
                            ? AppStrings.voucherCounterpartyLabel
                            : AppStrings.voucherAffectedAccountParty,
                        slot: QaydTextStyleSlot.labelLarge,
                      ),
                      subtitle: QaydText(
                        _counterparty?.name ??
                            AppStrings.voucherPickCounterpartyHint2,
                        slot: QaydTextStyleSlot.bodyLarge,
                        color: _counterparty == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                      trailing: Icon(Icons.chevron_left_rounded, color: gold),
                      onTap: _pickCounterparty,
                    ),

                    if (_canPickAffectedAccount || _affected == null) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: QaydText(
                          _type == VoucherType.payment
                              ? AppStrings.voucherAffectedAccountPaymentTitle
                              : AppStrings.voucherAffectedAccountReceiptTitle,
                          slot: QaydTextStyleSlot.labelLarge,
                        ),
                        subtitle: QaydText(
                          _affected?.name ??
                              AppStrings.voucherAffectedAccountHint,
                          slot: QaydTextStyleSlot.bodyLarge,
                          color: _affected == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : null,
                        ),
                        trailing: Icon(Icons.chevron_left_rounded, color: gold),
                        onTap: _pickAffectedAccount,
                      ),
                    ],

                    // if (_counterparty != null) _buildSuggestionsStrip(context),
                    SizedBox(height: SpacingTokens.md),
                    SlideTransition(
                      position: _slideOffset,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QaydAmountField(
                            controller: _amountController,
                            label: AppStrings.voucherAmountLabel,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: SpacingTokens.md),
                          QaydTextField(
                            controller: _descriptionController,
                            label: AppStrings.voucherDescriptionLabel,
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                          ),
                          if (_qrSenderSignatureHex != null)
                            _buildSignatureStatusBanner(gold),
                          SizedBox(height: SpacingTokens.md),

                          CostCenterTagSelector(
                            initialTags: _costCenterTags,
                            onChanged: (tags) =>
                                setState(() => _costCenterTags = tags),
                          ),

                          SizedBox(height: SpacingTokens.md),

                          // ── Attachment & Collateral Actions ──────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickAttachments,
                                  icon: Icon(Icons.attach_file_rounded,
                                      size: 18, color: gold),
                                  label: Text(
                                    AppStrings.voucherAttachImages,
                                    style: TextStyle(color: gold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: gold.withValues(alpha: 0.4)),
                                  ),
                                ),
                              ),
                              SizedBox(width: SpacingTokens.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _addCollateral,
                                  icon: Icon(Icons.shield_rounded,
                                      size: 18, color: gold),
                                  label: Text(
                                    AppStrings.voucherAddCollateral,
                                    style: TextStyle(color: gold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: gold.withValues(alpha: 0.4)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Image thumbnails ────────────────────
                          if (_pickedImages.isNotEmpty) ...[
                            SizedBox(height: SpacingTokens.sm),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _pickedImages.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: SpacingTokens.xs),
                                itemBuilder: (context, i) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
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
                                            () => _pickedImages.removeAt(i),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],

                          // ── Collateral summary ──────────────────
                          if (_collateralInput != null) ...[
                            SizedBox(height: SpacingTokens.sm),
                            Container(
                              padding: const EdgeInsets.all(SpacingTokens.sm),
                              decoration: BoxDecoration(
                                color: gold.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: gold.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_rounded,
                                      size: 18, color: gold),
                                  SizedBox(width: SpacingTokens.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _collateralInput!.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                        ),
                                        Text(
                                          '${AppStrings.voucherCollateralValuePrefix}${(_collateralInput!.estimatedValueMinor / 100).toStringAsFixed(2)} $_currencyCode',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                    onPressed: () => setState(
                                      () => _collateralInput = null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: SpacingTokens.xl),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: submitting ? null : _submit,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: gold,
                                    side: BorderSide(color: gold),
                                  ),
                                  child: Text(AppStrings.voucherSaveDraft),
                                ),
                              ),
                              SizedBox(width: SpacingTokens.md),
                              Expanded(
                                child: FilledButton(
                                  onPressed: submitting ? null : _submitConfirm,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: submitting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Text(AppStrings.voucherConfirmAndSend),
                                ),
                              ),
                            ],
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

  Widget _buildDateTile(Color gold) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: QaydText(
          AppStrings.voucherDateLabel,
          slot: QaydTextStyleSlot.bodyMedium,
        ),
        subtitle: QaydText(
          MaterialLocalizations.of(context).formatFullDate(_date),
          slot: QaydTextStyleSlot.titleSmall,
        ),
        trailing: Icon(Icons.calendar_month_rounded, color: gold),
        onTap: _pickDate,
      );

  Widget _buildCurrencyTile(Color gold) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: QaydText(
          AppStrings.voucherCurrencyLabel,
          slot: QaydTextStyleSlot.bodyMedium,
        ),
        subtitle: QaydText(
          _currencyCode,
          slot: QaydTextStyleSlot.titleSmall,
        ),
        trailing: Icon(Icons.currency_exchange_rounded, color: gold),
        onTap: _pickCurrency,
      );

  Widget _buildSignatureStatusBanner(Color gold) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: _isQrSignatureValid
            ? ColorTokens.emerald500.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isQrSignatureValid
              ? ColorTokens.emerald500.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isQrSignatureValid
                ? Icons.verified_user_rounded
                : Icons.warning_amber_rounded,
            color: _isQrSignatureValid ? ColorTokens.emerald500 : Colors.orange,
            size: 20,
          ),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: QaydText(
              _isQrSignatureValid
                  ? AppStrings.voucherSignatureMatchesData
                  : AppStrings.voucherSignatureMismatchData,
              slot: QaydTextStyleSlot.bodySmall,
              color: _isQrSignatureValid
                  ? ColorTokens.emerald700
                  : Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

  // Widget _buildSuggestionsStrip(BuildContext context) {
  //   return BlocBuilder<VoucherSuggestionsCubit, VoucherSuggestionsState>(
  //     builder: (context, sug) {
  //       if (sug is VoucherSuggestionsLoading) {
  //         return Padding(
  //           padding: const EdgeInsets.only(top: SpacingTokens.md),
  //           child: AnimatedOpacity(
  //             opacity: 0.45,
  //             duration: const Duration(milliseconds: 280),
  //             child: Center(
  //               child: SizedBox(
  //                 width: 22,
  //                 height: 22,
  //                 child: CircularProgressIndicator(strokeWidth: 2),
  //               ),
  //             ),
  //           ),
  //         );
  //       }
  //       if (sug is! VoucherSuggestionsReady || sug.suggestions.isEmpty) {
  //         return const SizedBox.shrink();
  //       }
  //       return Padding(
  //         padding: const EdgeInsets.only(top: SpacingTokens.md),
  //         child: AnimatedOpacity(
  //           opacity: 1,
  //           duration: const Duration(milliseconds: 420),
  //           curve: Curves.easeOut,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               QaydText(
  //                 AppStrings.smartSuggestionsTitle,
  //                 slot: QaydTextStyleSlot.titleSmall,
  //               ),
  //               SizedBox(height: SpacingTokens.sm),
  //               SizedBox(
  //                 height: 140,
  //                 child: ListView.separated(
  //                   scrollDirection: Axis.horizontal,
  //                   itemCount: sug.suggestions.length,
  //                   separatorBuilder: (_, __) =>
  //                       SizedBox(width: SpacingTokens.sm),
  //                   itemBuilder: (context, i) {
  //                     final s = sug.suggestions[i];
  //                     return _SuggestionCard(
  //                       suggestion: s,
  //                       typeLabel: _typeLabel,
  //                       onAccept: () => context
  //                           .read<VoucherSuggestionsCubit>()
  //                           .acceptAndMarkProcessed(s),
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

// ── Suggestion card (unchanged) ──────────────────────────────────────────────

// class _SuggestionCard extends StatelessWidget {
//   const _SuggestionCard({
//     required this.suggestion,
//     required this.typeLabel,
//     required this.onAccept,
//   });

//   final ScoredSuggestionDto suggestion;
//   final String Function(VoucherType) typeLabel;
//   final VoidCallback onAccept;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final amt = suggestion.amountMinorUnits != null
//         ? formatMinorAmountForField(suggestion.amountMinorUnits!)
//         : '—';
//     final dateStr = suggestion.date != null
//         ? DateFormat.yMMMd('ar').format(suggestion.date!)
//         : '—';
//     final typeStr = suggestion.type != null ? typeLabel(suggestion.type!) : '—';

//     return Material(
//       color: ColorTokens.navy800.withValues(alpha: 0.35),
//       borderRadius: BorderRadius.circular(12),
//       child: Padding(
//         padding: const EdgeInsets.all(SpacingTokens.md),
//         child: SizedBox(
//           width: 168,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${AppStrings.smartSuggestionAmount}: $amt',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: theme.textTheme.bodySmall,
//               ),
//               Text(
//                 '${AppStrings.smartSuggestionDate}: $dateStr',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: theme.textTheme.bodySmall,
//               ),
//               Text(
//                 '${AppStrings.smartSuggestionType}: $typeStr',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: theme.textTheme.bodySmall,
//               ),
//               Align(
//                 alignment: AlignmentDirectional.centerEnd,
//                 child: FilledButton.tonal(
//                   onPressed: onAccept,
//                   child: Text(AppStrings.smartSuggestionAccept),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
