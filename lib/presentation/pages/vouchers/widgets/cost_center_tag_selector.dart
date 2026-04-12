import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';

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
      ).showSnackBar(const SnackBar(content: Text('لا يوجد مراكز تكلفة .')));
      return;
    }
    final available = centers
        .where((c) => !_selectedTags.any((t) => t.costCenterId == c.id))
        .toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة جميع مراكز التكلفة المتاحة.'),
          ),
        );
      }
      return;
    }

    final selectedCenter = await showModalBottomSheet<CostCenter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CostCenterPickerSheet(centers: available),
    );

    if (selectedCenter != null && mounted) {
      // Pick dimensions for this center
      final dimRes = await InjectionContainer.manageDimensionsUseCase
          .listDimensions(costCenterId: selectedCenter.id);

      List<String> selectedDims = [];
      if (dimRes.isSuccess && dimRes.valueOrNull!.isNotEmpty) {
        final picked = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _DimensionPickerSheet(
            centerName: selectedCenter.name,
            dimensions: dimRes.valueOrNull!,
          ),
        );
        if (picked != null) selectedDims = picked;
      }

      setState(() {
        _selectedTags.add(
          CostCenterTagInput(
            costCenterId: selectedCenter.id,
            dimensionIds: selectedDims,
          ),
        );
      });
      _notify();
    }
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
              widget.label ?? 'مراكز التكلفة والأبعاد',
              slot: QaydTextStyleSlot.labelLarge,
            ),
            TextButton.icon(
              onPressed: _addCostCenter,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('إضافة'),
            ),
          ],
        ),
        if (_selectedTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            child: Text(
              'لا توجد مراكز تكلفة مرتبطة.',
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

class _CostCenterPickerSheet extends StatelessWidget {
  const _CostCenterPickerSheet({required this.centers});

  final List<CostCenter> centers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QaydText('اختر مركز التكلفة', slot: QaydTextStyleSlot.titleMedium),
          const SizedBox(height: SpacingTokens.md),
          ...centers.map(
            (c) => ListTile(
              title: Text(c.name),
              leading: const Icon(Icons.pie_chart_outline_rounded),
              onTap: () => Navigator.pop(context, c),
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
        ],
      ),
    );
  }
}

class _DimensionPickerSheet extends StatefulWidget {
  const _DimensionPickerSheet({
    required this.centerName,
    required this.dimensions,
  });

  final String centerName;
  final List<CostCenterDimension> dimensions;

  @override
  State<_DimensionPickerSheet> createState() => _DimensionPickerSheetState();
}

class _DimensionPickerSheetState extends State<_DimensionPickerSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QaydText(
            'أبعاد ${widget.centerName}',
            slot: QaydTextStyleSlot.titleMedium,
          ),
          const SizedBox(height: SpacingTokens.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: widget.dimensions.map((d) {
                return CheckboxListTile(
                  title: Text(d.name),
                  subtitle: Text(d.category.name),
                  value: _selectedIds.contains(d.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedIds.add(d.id);
                      } else {
                        _selectedIds.remove(d.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _selectedIds.toList()),
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
        ],
      ),
    );
  }
}
