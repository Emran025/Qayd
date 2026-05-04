import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/accounts/dtos/update_account_input.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_numeric_field.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/accounts/account_create_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_edit_cubit.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/inputs/phone_zone.dart';
import 'package:qayd/domain/services/counterparty_qr_service.dart';
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
    // Edit-mode: when provided the page behaves as an edit form.
    this.editData,
  });

  final String? parentAccountId;
  final String? parentName;
  final String? parentStandardKind;
  final bool forcedIsChild;
  final List<StandardAccountClassificationKind>? allowedStandardKinds;

  /// When set, the page enters **edit mode**: form fields are pre-filled with
  /// existing account data and saving calls [AccountEditCubit] instead of
  /// [AccountCreateCubit].
  final GetAccountDetailsOutput? editData;

  bool get isEditMode => editData != null;
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

  StandardAccountClassificationKind _standardKind =
      StandardAccountClassificationKind.liquidAssets;
  bool _useCustomRootClassification = false;
  AccountNature _customNature = AccountNature.debit;

  CounterpartyQrData? _scannedData;
  List<CostCenterTagInput> _costCenterTags = [];

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode) {
      _prefillFromEditData(widget.editData!);
    } else {
      _parentId = widget.parentAccountId;
      _parentName = widget.parentName;
      _parentStandardKind = widget.parentStandardKind;
      if (widget.allowedStandardKinds?.isNotEmpty == true) {
        _standardKind = widget.allowedStandardKinds!.first;
      }
    }
  }

  /// Pre-fills all form controllers from the existing account details.
  void _prefillFromEditData(GetAccountDetailsOutput d) {
    _nameController.text = d.name;
    _parentId = d.parentId;
    _parentName = d.parentName;
    _parentStandardKind = d.standardClassificationKind;

    if (d.standardClassificationKind != null) {
      _useCustomRootClassification = false;
      try {
        _standardKind = StandardAccountClassificationKind.values
            .byName(d.standardClassificationKind!);
      } catch (_) {}
    } else {
      _useCustomRootClassification = true;
      _customClassController.text = d.customClassificationName ?? '';
      _customNature =
          d.natureCode == 'credit' ? AccountNature.credit : AccountNature.debit;
    }

    void split(
        String? raw, TextEditingController zone, TextEditingController num) {
// ... existing split logic ...
      if (raw == null || raw.isEmpty) return;
      final p = raw.replaceAll(RegExp(r'[^\d]'), '');
      if (p.length >= 9) {
        num.text = p.substring(p.length - 9);
        zone.text = p.substring(0, p.length - 9);
      } else {
        num.text = p;
      }
    }

    split(d.phoneNumber, _phoneZoneController, _phoneController);
    split(d.whatsappNumber, _whatsappZoneController, _whatsappController);

    _bankInfoController.text = d.bankAccountInfo ?? '';
    _partyTypeController.text = d.partyType ?? '';

    _costCenterTags = d.defaultCostCenters
        .map(
          (cc) => CostCenterTagInput(
            costCenterId: cc.costCenterId,
            dimensionIds: cc.dimensionIds,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
// ...
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _isChild =>
      widget.forcedIsChild ||
      widget.parentAccountId != null ||
      (widget.isEditMode && widget.editData?.parentId != null);

  bool get _showPartyDetails {
    if (widget.isEditMode) {
      // For existing accounts, we use the CURRENT state's kind to decide if we show party fields.
      // If the user is BUSY reclassifying it in the UI, we might want to adapt,
      // but for now let's stick to the loaded classification's requirement.
      final kind = _isChild
          ? _parentStandardKind
          : (_useCustomRootClassification ? null : _standardKind.name);
      return kind == StandardAccountClassificationKind.receivables.name ||
          kind == StandardAccountClassificationKind.payables.name;
    }
    if (!_isChild) return false;
    final kind = _parentStandardKind;
    return kind == StandardAccountClassificationKind.receivables.name ||
        kind == StandardAccountClassificationKind.payables.name;
  }

  String _buildPhone(TextEditingController zone, TextEditingController num) =>
      (zone.text + num.text).replaceAll(' ', '').replaceAll('+', '');

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // ── Edit mode ─────────────────────────────────────────────────────────────
    if (widget.isEditMode) {
      final input = UpdateAccountInput(
        accountId: widget.editData!.accountId,
        newName: _nameController.text.trim(),
        parentAccountId: _isChild ? _parentId : null,
        rootStandardKind:
            !_isChild && !_useCustomRootClassification ? _standardKind : null,
        customClassificationName: !_isChild && _useCustomRootClassification
            ? _customClassController.text.trim()
            : null,
        customClassificationNature:
            !_isChild && _useCustomRootClassification ? _customNature : null,
        phoneNumber: _showPartyDetails
            ? _buildPhone(_phoneZoneController, _phoneController)
            : null,
        whatsappNumber: _showPartyDetails
            ? _buildPhone(_whatsappZoneController, _whatsappController)
            : null,
        bankAccountInfo:
            _showPartyDetails ? _bankInfoController.text.trim() : null,
        partyType: _showPartyDetails ? _partyTypeController.text.trim() : null,
        defaultCostCenters: _costCenterTags,
      );
      await context.read<AccountEditCubit>().submit(input);
      return;
    }

    // ── Create mode ───────────────────────────────────────────────────────────
    if (!_isChild && _useCustomRootClassification) {
      if (_customClassController.text.trim().isEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text(AppStrings.customClassificationNameRequired),
        ));
        return;
      }
    }
    if (_isChild && _parentId == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(AppStrings.pickAccountTitle),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final input = CreateAccountInput(
      name: _nameController.text,
      parentAccountId: _parentId,
      rootStandardKind:
          !_isChild && !_useCustomRootClassification ? _standardKind : null,
      customClassificationName: !_isChild && _useCustomRootClassification
          ? _customClassController.text.trim()
          : null,
      customClassificationNature:
          !_isChild && _useCustomRootClassification ? _customNature : null,
      phoneNumber: _showPartyDetails
          ? _buildPhone(_phoneZoneController, _phoneController)
          : null,
      whatsappNumber: _showPartyDetails
          ? _buildPhone(_whatsappZoneController, _whatsappController)
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
// ...
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
// ...
    if (widget.isEditMode) {
      return BlocConsumer<AccountEditCubit, AccountEditState>(
        listener: (ctx, state) {
          if (state is AccountEditSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(AppStrings.accountUpdatedSuccess),
              behavior: SnackBarBehavior.floating,
            ));
            Navigator.of(ctx).pop(true);
          }
          if (state is AccountEditFailure) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.failure.messageAr),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (ctx, state) =>
            _buildScaffold(submitting: state is AccountEditSubmitting),
      );
    }

    return BlocConsumer<AccountCreateCubit, AccountCreateState>(
      listener: (ctx, state) {
// ...
        if (state is AccountCreateSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(AppStrings.accountCreatedSuccess),
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.of(ctx).pop(true);
        }
        if (state is AccountCreateFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.failure.messageAr),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (ctx, state) =>
          _buildScaffold(submitting: state is AccountCreateSubmitting),
    );
  }

  Widget _buildScaffold({required bool submitting}) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    final title = widget.isEditMode
        ? AppStrings.editAccountTitle
        : _isChild
            ? AppStrings.newChildAccountTitle
            : AppStrings.newRootAccountTitle;

    return Scaffold(
      appBar: QaydAppBar(
        title: title,
        actions: [
          if (_showPartyDetails && !widget.isEditMode)
            IconButton(
              tooltip: AppStrings.identityQrScanTitle,
              icon: Icon(Icons.qr_code_scanner_rounded),
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
              // ── Classification / parent ──────────────────────────────────
              if (_isChild) ...[
                _ParentAccountPicker(
                  parentId: _parentId,
                  parentName: _parentName,
                  gold: gold,
                  submitting: submitting,
                  allowedStandardKinds: widget.allowedStandardKinds,
                  onPicked: (id, name, kind) => setState(() {
                    _parentId = id;
                    _parentName = name;
                    _parentStandardKind = kind;
                  }),
                ),
                SizedBox(height: SpacingTokens.md),
              ] else ...[
                QaydText(
                  AppStrings.classificationSectionTitle,
                  slot: QaydTextStyleSlot.titleMedium,
                ),
                SizedBox(height: SpacingTokens.sm),
                SegmentedButton<bool>(
                  segments:  [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(AppStrings.standardClassificationTab),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(AppStrings.customClassificationTab),
                    ),
                  ],
                  selected: {_useCustomRootClassification},
                  onSelectionChanged: (s) =>
                      setState(() => _useCustomRootClassification = s.first),
                ),
                SizedBox(height: SpacingTokens.md),
                if (!_useCustomRootClassification)
                  _StandardKindSelector(
                    selected: _standardKind,
                    allowedKinds: widget.allowedStandardKinds,
                    onChanged: (k) => setState(() => _standardKind = k),
                  )
                else ...[
                  QaydTextField(
                    controller: _customClassController,
                    label: AppStrings.customClassificationNameLabel,
                    validator: (v) {
                      if (!_useCustomRootClassification) return null;
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.customClassificationNameRequired;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SpacingTokens.md),
                  QaydText(
                    AppStrings.customNatureLabel,
                    slot: QaydTextStyleSlot.bodyMedium,
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  SegmentedButton<AccountNature>(
                    segments: [
                      ButtonSegment<AccountNature>(
                        value: AccountNature.debit,
                        label: Text(AppStrings.natureDebitShort),
                      ),
                      ButtonSegment<AccountNature>(
                        value: AccountNature.credit,
                        label: Text(AppStrings.natureCreditShort),
                      ),
                    ],
                    selected: {_customNature},
                    onSelectionChanged: (s) =>
                        setState(() => _customNature = s.first),
                  ),
                ],
              ],

              if (widget.isEditMode) ...[
                SizedBox(height: SpacingTokens.sm),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.orange.shade800),
                    SizedBox(width: SpacingTokens.xs),
                    Expanded(
                      child: QaydText(
                        AppStrings.modifyingTheClassificationOr,
                        slot: QaydTextStyleSlot.labelSmall,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: SpacingTokens.lg),

              // ── Account name ───────────────────────────────────────────────
              QaydTextField(
                controller: _nameController,
                label: AppStrings.accountNameLabel,
                textInputAction: _showPartyDetails
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppStrings.accountNameRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: SpacingTokens.xl),

              // ── Party details ──────────────────────────────────────────────
              if (_showPartyDetails) ...[
                QaydText(
                  AppStrings.partyDetailsSection,
                  slot: QaydTextStyleSlot.titleMedium,
                ),
                SizedBox(height: SpacingTokens.md),
                PhoneZoneForm(
                  zoneController: _phoneZoneController,
                  phoneController: _phoneController,
                  label: AppStrings.partyPhoneLabel,
                ),
                SizedBox(height: SpacingTokens.sm),
                PhoneZoneForm(
                  zoneController: _whatsappZoneController,
                  phoneController: _whatsappController,
                  label: AppStrings.partyWhatsappLabel,
                ),
                SizedBox(height: SpacingTokens.sm),
                QaydNumericField(
                  controller: _bankInfoController,
                  label: AppStrings.partyBankInfoLabel,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: SpacingTokens.sm),
                QaydTextField(
                  controller: _partyTypeController,
                  label: AppStrings.partyTypeLabel,
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: SpacingTokens.xl),
              ],

              // ── Default cost centres ───────────────────────────────────────
              QaydText(
                AppStrings.virtualCostCenters,
                slot: QaydTextStyleSlot.titleSmall,
              ),
              SizedBox(height: SpacingTokens.md),
              CostCenterTagSelector(
                initialTags: _costCenterTags,
                onChanged: (tags) => setState(() => _costCenterTags = tags),
                label: AppStrings.addADefaultCost,
              ),
              SizedBox(height: SpacingTokens.xl),

              // ── Save button ────────────────────────────────────────────────
              FilledButton(
                onPressed: submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: submitting
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isEditMode
                            ? AppStrings.saveAccountChanges
                            : AppStrings.saveAccount,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Parent account picker (create-only widget) ──────────────────────────────

class _ParentAccountPicker extends StatelessWidget {
  const _ParentAccountPicker({
    required this.parentId,
    required this.parentName,
    required this.gold,
    required this.submitting,
    required this.allowedStandardKinds,
    required this.onPicked,
    // required this.editMode,
  });

  final String? parentId;
  final String? parentName;
  final Color gold;
  final bool submitting;
  final List<StandardAccountClassificationKind>? allowedStandardKinds;
  final void Function(String id, String name, String? kind) onPicked;
  // final bool editMode;

  @override
  Widget build(BuildContext context) {
    // We EXCLUDE specific sensitive/system classifications to allow for future expansion.
    final excludedKinds = [
      StandardAccountClassificationKind.liquidAssets.name,
      StandardAccountClassificationKind.personalExpenses.name,
      StandardAccountClassificationKind.fixedDepreciableAssets.name,
      StandardAccountClassificationKind.fixedProfitableAssets.name,
      StandardAccountClassificationKind.clearingRemittances.name,
      StandardAccountClassificationKind.remittanceFees.name,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: submitting
            ? null
            : () async {
                final root = await showAccountPickerSheet(
                  context,
                  listAccounts: InjectionContainer.listAccountsUseCase,
                  requireNoRoot: false,
                  rootAllowed: true,
                  onlyRoots: true,
                  hideSterileRoots: true,
                  // We pass null to allowedClassifications and filter manually, 
                  // or just pass a long list. For now, let's filter the values.
                  allowedClassifications: StandardAccountClassificationKind.values
                      .map((k) => k.name)
                      .where((n) => !excludedKinds.contains(n))
                      .toList(),
                );
                if (root != null) {
                  onPicked(root.id, root.name, root.standardClassificationKind);
                }
              },
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QaydText(
                      parentName ?? AppStrings.pickAccountTitle,
                      slot: QaydTextStyleSlot.titleMedium,
                      color: parentId != null
                          ? gold
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: SpacingTokens.xs),
                    QaydText(
                      AppStrings.parentAccountLabel,
                      slot: QaydTextStyleSlot.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Standard kind selector (unchanged) ─────────────────────────────────────

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
    // We EXCLUDE specific sensitive/system classifications to allow for future expansion.
    final excludedKinds = {
      StandardAccountClassificationKind.liquidAssets,
      StandardAccountClassificationKind.personalExpenses,
      StandardAccountClassificationKind.fixedDepreciableAssets,
      StandardAccountClassificationKind.fixedProfitableAssets,
      StandardAccountClassificationKind.clearingRemittances,
      StandardAccountClassificationKind.remittanceFees,
    };

    final kinds = (allowedKinds ?? StandardAccountClassificationKind.values)
        .where((k) => !excludedKinds.contains(k))
        .toList();

    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: [
        for (final k in kinds)
          FilterChip(
            selected: selected == k,
            label: Text(AppStrings.standardClassificationLabel(k.name)),
            onSelected: (_) => onChanged(k),
          ),
      ],
    );
  }
}
