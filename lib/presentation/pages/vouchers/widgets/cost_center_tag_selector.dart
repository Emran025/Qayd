import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/widgets/cost_center_selection_sheet.dart';

class CostCenterTagSelector extends StatefulWidget {
  const CostCenterTagSelector({
    super.key,
    required this.onChanged,
    this.initialTags = const [],
    this.label,
  });

  final ValueChanged<List<CostCenterTagInput>> onChanged;
  final List<CostCenterTagInput> initialTags;
  final String? label;

  @override
  State<CostCenterTagSelector> createState() => _CostCenterTagSelectorState();
}

class _CostCenterTagSelectorState extends State<CostCenterTagSelector> {
  final List<CostCenterTagInput> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _selectedTags.addAll(widget.initialTags);
  }

  @override
  void didUpdateWidget(CostCenterTagSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTags != oldWidget.initialTags) {
      setState(() {
        _selectedTags.clear();
        _selectedTags.addAll(widget.initialTags);
      });
    }
  }

  void _notify() => widget.onChanged(List.unmodifiable(_selectedTags));

  Future<void> _addCostCenter() async {
    final res = await InjectionContainer.listCostCentersUseCase.call(
      activeOnly: true,
    );
    if (!res.isSuccess || !mounted) return;

    final centers = res.valueOrNull!;
    // Exclude already selected
    if (centers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStringsAr.costCenterNoCentersAvailable)));
      return;
    }
    final available = centers
        .where((c) => !_selectedTags.any((t) => t.costCenterId == c.id))
        .toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStringsAr.costCenterAllAddedAllAvailable),
          ),
        );
      }
      return;
    }

    final result = await showCostCenterSelectionSheet(
      context,
      availableCenters: available,
    );
    if (result == null || !mounted) return;

    setState(() {
      _selectedTags.add(
        CostCenterTagInput(
          costCenterId: result.center.id,
          dimensionIds: result.dimensionIds,
        ),
      );
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QaydText(
              widget.label ?? AppStringsAr.costCenterTagsLabel,
              slot: QaydTextStyleSlot.labelLarge,
            ),
            TextButton.icon(
              onPressed: _addCostCenter,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(AppStringsAr.actionAdd),
            ),
          ],
        ),
        if (_selectedTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            child: Text(
              AppStringsAr.costCenterNoneLinked,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: _selectedTags.map((tag) {
              return FutureBuilder<Result<CostCenterDetailsDto>>(
                future: InjectionContainer.getCostCenterDetailsUseCase.call(
                  tag.costCenterId,
                ),
                builder: (context, snapshot) {
                  final name = snapshot.data?.valueOrNull?.center.name ?? '...';
                  return Chip(
                    label: Text('$name (${tag.dimensionIds.length})'),
                    onDeleted: () {
                      setState(() => _selectedTags.remove(tag));
                      _notify();
                    },
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
