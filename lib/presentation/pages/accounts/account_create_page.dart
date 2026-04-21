import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_numeric_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/accounts/account_create_cubit.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/inputs/phone_zone.dart';
import 'package:qayd/presentation/pages/accounts/counterparty_qr_scanner_page.dart';
import 'package:qayd/domain/services/counterparty_qr_service.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/cost_center_tag_selector.dart';

class AccountCreatePage extends StatefulWidget {
  const AccountCreatePage({
    super.key,
    this.parentAccountId,
    this.parentName,
    this.parentStandardKind,
    this.forcedIsChild = false,
    this.allowedStandardKinds,
  });

  final String? parentAccountId;
  final String? parentName;
  final String? parentStandardKind;
  final bool forcedIsChild;
  final List<StandardAccountClassificationKind>? allowedStandardKinds;

  bool get isChild => forcedIsChild || parentAccountId != null;

  @override
  State<AccountCreatePage> createState() => _AccountCreatePageState();
}

class _AccountCreatePageState extends State<AccountCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customClassController = TextEditingController();

  final _phoneZoneController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappZoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _bankInfoController = TextEditingController();
  final _partyTypeController = TextEditingController();

  String? _parentId;
  String? _parentName;
  String? _parentStandardKind;

  @override
  void initState() {
    super.initState();
    _parentId = widget.parentAccountId;
    _parentName = widget.parentName;
    _parentStandardKind = widget.parentStandardKind;

    if (widget.allowedStandardKinds != null &&
        widget.allowedStandardKinds!.isNotEmpty) {
      _standardKind = widget.allowedStandardKinds!.first;
    }
  }

  StandardAccountClassificationKind _standardKind =
      StandardAccountClassificationKind.liquidAssets;
  bool _useCustomRootClassification = false;
  AccountNature _customNature = AccountNature.debit;

  // Stored data from QR scan
  CounterpartyQrData? _scannedData;

  List<CostCenterTagInput> _costCenterTags = [];

  bool get _showPartyDetails {
    if (!widget.isChild) return false;
    final kind = _parentStandardKind;
    return kind == StandardAccountClassificationKind.receivables.name ||
        kind == StandardAccountClassificationKind.payables.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customClassController.dispose();
    _phoneZoneController.dispose();
    _phoneController.dispose();
    _whatsappZoneController.dispose();
    _whatsappController.dispose();
    _bankInfoController.dispose();
    _partyTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!widget.isChild && _useCustomRootClassification) {
      if (_customClassController.text.trim().isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppStringsAr.customClassificationNameRequired),
          ),
        );
        return;
      }
    }

    if (widget.isChild && _parentId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStringsAr.pickAccountTitle),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final input = CreateAccountInput(
      name: _nameController.text,
      parentAccountId: _parentId,
      rootStandardKind: !widget.isChild && !_useCustomRootClassification
          ? _standardKind
          : null,
      customClassificationName: !widget.isChild && _useCustomRootClassification
          ? _customClassController.text.trim()
          : null,
      customClassificationNature:
          !widget.isChild && _useCustomRootClassification
              ? _customNature
              : null,
      phoneNumber: _showPartyDetails
          ? (_phoneZoneController.text + _phoneController.text)
              .replaceAll(' ', '')
              .replaceAll('+', '')
          : null,
      whatsappNumber: _showPartyDetails
          ? (_whatsappZoneController.text + _whatsappController.text)
              .replaceAll(' ', '')
              .replaceAll('+', '')
          : null,
      bankAccountInfo:
          _showPartyDetails ? _bankInfoController.text.trim() : null,
      partyType: _showPartyDetails ? _partyTypeController.text.trim() : null,
      email: _scannedData?.email,
      currentPublicKeyHex: _scannedData?.currentPublicKeyHex,
      publicKeyHistoryHex: _scannedData?.publicKeyHistoryHex,
      serverAccountId: _scannedData?.serverAccountId,
      defaultCostCenters: _costCenterTags,
      metadata: {},
    );

    await context.read<AccountCreateCubit>().submit(input);
  }

  Future<void> _scanCounterparty() async {
    final data = await Navigator.of(context).push<CounterpartyQrData?>(
      QaydPageRoute.slideFromStart<CounterpartyQrData?>(
        builder: (ctx) => const CounterpartyQrScannerPage(),
      ),
    );

    if (data != null) {
      setState(() {
        _scannedData = data;
        _nameController.text = data.name;

        // Simple phone splitting (last 9 digits for phone, rest for zone)
        // or just put all in phone and rely on manual adjustment if needed.
        // Protocol §3 says phone is immutable on import, but UI should reflect it.
        if (data.phone.isNotEmpty) {
          final p = data.phone.replaceAll('+', '').replaceAll(' ', '');
          if (p.length >= 9) {
            _phoneController.text = p.substring(p.length - 9);
            _phoneZoneController.text = p.substring(0, p.length - 9);
          } else {
            _phoneController.text = p;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStringsAr.identityQrScanSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final title = widget.isChild
        ? AppStringsAr.newChildAccountTitle
        : AppStringsAr.newRootAccountTitle;

    return BlocConsumer<AccountCreateCubit, AccountCreateState>(
      listener: (context, state) {
        if (state is AccountCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStringsAr.accountCreatedSuccess),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
        if (state is AccountCreateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.messageAr),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final submitting = state is AccountCreateSubmitting;

        return Scaffold(
          appBar: QaydAppBar(
            title: title,
            actions: [
              if (_showPartyDetails)
                IconButton(
                  tooltip: AppStringsAr.identityQrScanTitle,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  onPressed: _scanCounterparty,
                ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                children: [
                  if (widget.isChild) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: submitting
                            ? null
                            : () async {
                                final root = await showAccountPickerSheet(
                                  context,
                                  listAccounts:
                                      InjectionContainer.listAccountsUseCase,
                                  requireNoRoot: false,
                                  rootAllowed: true,
                                  onlyRoots: true,
                                  hideSterileRoots: true,
                                  allowedClassifications: widget
                                      .allowedStandardKinds
                                      ?.map((k) => k.name)
                                      .toList(),
                                );
                                if (root != null && mounted) {
                                  setState(() {
                                    _parentId = root.id;
                                    _parentName = root.name;
                                    _parentStandardKind =
                                        root.standardClassificationKind;
                                  });
                                }
                              },
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                        child: Container(
                          padding: const EdgeInsets.all(SpacingTokens.md),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(
                              RadiusTokens.md,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    QaydText(
                                      _parentName ??
                                          AppStringsAr.pickAccountTitle,
                                      slot: QaydTextStyleSlot.titleMedium,
                                      color: _parentId != null
                                          ? gold
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: SpacingTokens.xs),
                                    QaydText(
                                      AppStringsAr.parentAccountLabel,
                                      slot: QaydTextStyleSlot.bodySmall,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                  ],
                  if (!widget.isChild) ...[
                    QaydText(
                      AppStringsAr.classificationSectionTitle,
                      slot: QaydTextStyleSlot.titleMedium,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(AppStringsAr.standardClassificationTab),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(AppStringsAr.customClassificationTab),
                        ),
                      ],
                      selected: {_useCustomRootClassification},
                      onSelectionChanged: (s) {
                        setState(() => _useCustomRootClassification = s.first);
                      },
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    if (!_useCustomRootClassification)
                      _StandardKindSelector(
                        selected: _standardKind,
                        allowedKinds: widget.allowedStandardKinds,
                        onChanged: (k) => setState(() => _standardKind = k),
                      )
                    else ...[
                      QaydTextField(
                        controller: _customClassController,
                        label: AppStringsAr.customClassificationNameLabel,
                        validator: (v) {
                          if (!_useCustomRootClassification) {
                            return null;
                          }
                          if (v == null || v.trim().isEmpty) {
                            return AppStringsAr
                                .customClassificationNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: SpacingTokens.md),
                      QaydText(
                        AppStringsAr.customNatureLabel,
                        slot: QaydTextStyleSlot.bodyMedium,
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      SegmentedButton<AccountNature>(
                        segments: [
                          ButtonSegment<AccountNature>(
                            value: AccountNature.debit,
                            label: Text(AppStringsAr.natureDebitShort),
                          ),
                          ButtonSegment<AccountNature>(
                            value: AccountNature.credit,
                            label: Text(AppStringsAr.natureCreditShort),
                          ),
                        ],
                        selected: {_customNature},
                        onSelectionChanged: (s) {
                          setState(() => _customNature = s.first);
                        },
                      ),
                    ],
                    const SizedBox(height: SpacingTokens.lg),
                  ],
                  QaydTextField(
                    controller: _nameController,
                    label: AppStringsAr.accountNameLabel,
                    textInputAction: _showPartyDetails
                        ? TextInputAction.next
                        : TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStringsAr.accountNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacingTokens.xl),
                  if (_showPartyDetails) ...[
                    QaydText(
                      AppStringsAr.partyDetailsSection,
                      slot: QaydTextStyleSlot.titleMedium,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    PhoneZoneForm(
                      zoneController: _phoneZoneController,
                      phoneController: _phoneController,
                      label: AppStringsAr.partyPhoneLabel,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    PhoneZoneForm(
                      zoneController: _whatsappZoneController,
                      phoneController: _whatsappController,
                      label: AppStringsAr.partyWhatsappLabel,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    QaydNumericField(
                      controller: _bankInfoController,
                      label: AppStringsAr.partyBankInfoLabel,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    QaydTextField(
                      controller: _partyTypeController,
                      label: AppStringsAr.partyTypeLabel,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: SpacingTokens.xl),
                  ],
                  QaydText(
                    'مراكز التكلفة الافتراضية',
                    slot: QaydTextStyleSlot.titleSmall,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  CostCenterTagSelector(
                    initialTags: _costCenterTags,
                    onChanged: (tags) => setState(() => _costCenterTags = tags),
                    label: 'إضافة مركز تكلفة افتراضي',
                  ),
                  const SizedBox(height: SpacingTokens.xl),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStringsAr.saveAccount),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StandardKindSelector extends StatelessWidget {
  const _StandardKindSelector({
    required this.selected,
    required this.onChanged,
    this.allowedKinds,
  });

  final StandardAccountClassificationKind selected;
  final List<StandardAccountClassificationKind>? allowedKinds;
  final ValueChanged<StandardAccountClassificationKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final kinds = (allowedKinds ?? StandardAccountClassificationKind.values)
        .where(
          (k) =>
              k != StandardAccountClassificationKind.fixedDepreciableAssets &&
              k != StandardAccountClassificationKind.fixedProfitableAssets,
        )
        .toList();
    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        for (final k in kinds)
          FilterChip(
            selected: selected == k,
            label: Text(AppStringsAr.standardClassificationLabel(k.name)),
            onSelected: (_) => onChanged(k),
          ),
      ],
    );
  }
}
