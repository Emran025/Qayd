import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class CostCenterSelectionResult {
  const CostCenterSelectionResult({
    required this.center,
    required this.dimensionIds,
  });
  final CostCenter center;
  final List<String> dimensionIds;
}

Future<CostCenterSelectionResult?> showCostCenterSelectionSheet(
  BuildContext context, {
  required List<CostCenter> availableCenters,
}) async {
  return showModalBottomSheet<CostCenterSelectionResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _CostCenterSelectionContent(centers: availableCenters);
    },
  );
}

class _CostCenterSelectionContent extends StatefulWidget {
  const _CostCenterSelectionContent({required this.centers});

  final List<CostCenter> centers;

  @override
  State<_CostCenterSelectionContent> createState() =>
      _CostCenterSelectionContentState();
}

class _CostCenterSelectionContentState
    extends State<_CostCenterSelectionContent> {
  CostCenter? _selectedCenter;
  bool _loadingDims = false;
  List<CostCenterDimension>? _dimensions;
  final Set<String> _selectedDims = {};

  Future<void> _onCenterPicked(CostCenter center, {bool customize = false}) async {
    setState(() {
      _selectedCenter = center;
      _loadingDims = true;
    });

    final dimRes = await InjectionContainer.manageDimensionsUseCase
        .listDimensions(costCenterId: center.id);

    if (!mounted) return;

    if (dimRes.isSuccess && dimRes.valueOrNull!.isNotEmpty) {
      if (customize) {
        setState(() {
          _dimensions = dimRes.valueOrNull;
          _selectedDims.clear();
          _selectedDims.addAll(_dimensions!.map((d) => d.id));
          _loadingDims = false;
        });
      } else {
        Navigator.of(context).pop(CostCenterSelectionResult(
          center: center,
          dimensionIds: dimRes.valueOrNull!.map((d) => d.id).toList(),
        ));
      }
    } else {
      Navigator.of(context).pop(CostCenterSelectionResult(
        center: center,
        dimensionIds: [],
      ));
    }
  }

  void _onDimensionsSubmitted() {
    if (_selectedCenter == null) return;
    Navigator.of(context).pop(CostCenterSelectionResult(
      center: _selectedCenter!,
      dimensionIds: _selectedDims.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 60% of screen height to allow nice scrolling
    final h = MediaQuery.sizeOf(context).height * 0.6;

    Widget content;

    if (_selectedCenter == null) {
      content = _buildCentersList();
    } else if (_loadingDims) {
      content = Center(child: CircularProgressIndicator());
    } else if (_dimensions != null) {
      content = _buildDimensionsList();
    } else {
      content = SizedBox(); // Fallback conceptually unreachable
    }

    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          height: h,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                child: QaydText(
                  _selectedCenter == null
                      ? AppStrings.costCenterSelectionTitle
                      : AppStrings.costCenterDimensionsTitle(_selectedCenter!.name),
                  slot: QaydTextStyleSlot.titleMedium,
                ),
              ),
              SizedBox(height: SpacingTokens.sm),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentersList() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      itemCount: widget.centers.length,
      itemBuilder: (ctx, i) {
        final c = widget.centers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorTokens.goldAccent.withValues(alpha: 0.1),
              foregroundColor: ColorTokens.goldAccent,
              child: Icon(Icons.pie_chart_rounded, size: 20),
            ),
            title: QaydText(c.name, slot: QaydTextStyleSlot.bodyLarge),
            trailing: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
              ),
              tooltip: AppStrings.costCenterCustomizeDimensions,
              onPressed: () => _onCenterPicked(c, customize: true),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            onTap: () => _onCenterPicked(c, customize: false),
          ),
        );
      },
    );
  }

  Widget _buildDimensionsList() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            itemCount: _dimensions!.length,
            itemBuilder: (ctx, i) {
              final d = _dimensions![i];
              final isSelected = _selectedDims.contains(d.id);
              return Container(
                margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: CheckboxListTile(
                  title: QaydText(
                    d.name,
                    slot: QaydTextStyleSlot.bodyLarge,
                  ),
                  subtitle: QaydText(
                    d.category.name,
                    slot: QaydTextStyleSlot.bodySmall,
                    color: scheme.onSurfaceVariant,
                  ),
                  value: isSelected,
                  activeColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedDims.add(d.id);
                      } else {
                        _selectedDims.remove(d.id);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: FilledButton(
            onPressed: _onDimensionsSubmitted,
            child: Text(AppStrings.costCenterApplyDimensions),
          ),
        ),
      ],
    );
  }
}
