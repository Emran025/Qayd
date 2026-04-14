import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/application/accounts/dtos/account_default_cost_center_dto.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/cost_center_selection_sheet.dart';
import 'package:qayd/core/result/result.dart';

class AccountDefaultCostCentersSection extends StatefulWidget {
  const AccountDefaultCostCentersSection({super.key, required this.data});
  final GetAccountDetailsOutput data;

  @override
  State<AccountDefaultCostCentersSection> createState() =>
      _AccountDefaultCostCentersSectionState();
}

class _AccountDefaultCostCentersSectionState
    extends State<AccountDefaultCostCentersSection> {
  late List<AccountDefaultCostCenterDto> _defaults;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _defaults = List.of(widget.data.defaultCostCenters);
  }

  Future<void> _add() async {
    // 1. Pick a cost center from the available list
    final res = await InjectionContainer.listCostCentersUseCase.call(
      activeOnly: true,
    );
    if (!res.isSuccess || !mounted) return;

    final allCenters = res.valueOrNull!;
    final available = allCenters
        .where((c) => !_defaults.any((d) => d.costCenterId == c.id))
        .toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStringsAr.costCenterAllAddedAllAvailable)),
        );
      }
      return;
    }

    final result = await showCostCenterSelectionSheet(
      context,
      availableCenters: available,
    );
    if (result == null || !mounted) return;

    // 2. Persist
    setState(() => _loading = true);
    final saveRes =
        await InjectionContainer.manageAccountDefaultCostCentersUseCase.save(
      accountId: AccountId(widget.data.accountId),
      costCenterId: result.center.id,
      dimensionIds: result.dimensionIds,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (saveRes.isSuccess) {
      setState(() {
        _defaults.add(AccountDefaultCostCenterDto(
          id: '',
          accountId: widget.data.accountId,
          costCenterId: result.center.id,
          costCenterName: result.center.name,
          dimensionIds: result.dimensionIds,
        ));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsAr.costCenterSaveError)),
      );
    }
  }

  Future<void> _remove(AccountDefaultCostCenterDto item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text(AppStringsAr.confirmDeletionTitle),
        content: Text(
          AppStringsAr.costCenterRemoveConfirmBody(item.costCenterName ?? item.costCenterId),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text(AppStringsAr.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text(AppStringsAr.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final res =
        await InjectionContainer.manageAccountDefaultCostCentersUseCase.remove(
      accountId: AccountId(widget.data.accountId),
      costCenterId: item.costCenterId,
    );
    if (!mounted) return;
    if (res.isSuccess) {
      setState(() => _defaults.removeWhere(
            (d) => d.costCenterId == item.costCenterId,
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsAr.costCenterRemoveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final custom = theme.extension<QaydCustomColors>()!;
    final gold = custom.goldAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          child: Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  color: ColorTokens.emerald600, size: 20),
              const SizedBox(width: SpacingTokens.sm),
              QaydText(AppStringsAr.defaultCostCentersTitle,
                  slot: QaydTextStyleSlot.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  AppStringsAr.defaultCostCentersDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                if (_loading)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_defaults.isEmpty)
                  Text(
                    AppStringsAr.defaultCostCentersEmpty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  )
                else
                  Wrap(
                    spacing: SpacingTokens.sm,
                    runSpacing: SpacingTokens.xs,
                    children: _defaults.map((d) {
                      final name = d.costCenterName ?? d.costCenterId;
                      final dimCount = d.dimensionIds.length;
                      return Chip(
                        avatar: Icon(
                          Icons.pie_chart_rounded,
                          size: 16,
                          color: gold,
                        ),
                        label: Text(
                          dimCount > 0 ? '$name ($dimCount)' : name,
                          style: theme.textTheme.labelSmall,
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        onDeleted: () => _remove(d),
                        backgroundColor: scheme.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                          side: BorderSide(
                            color: gold.withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: SpacingTokens.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: _loading ? null : _add,
                    icon: Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: gold),
                    label: Text(AppStringsAr.costCenterAddCenter, style: TextStyle(color: gold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
