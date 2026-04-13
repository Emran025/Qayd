import 'package:flutter/material.dart';
import 'package:qayd/application/cost_centers/dtos/dimension_breakdown_item.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Horizontal scroll of minimal filter chips for dimension filtering.
///
/// Instead of heavy section headers and explicit filter icons, the chips
/// serve as the *only* visual element. A subtle "×" clear action appears
/// inline when any chip is selected.
class FilterActionBar extends StatelessWidget {
  const FilterActionBar({
    super.key,
    required this.breakdownItems,
    required this.activeDimId,
    required this.typeColor,
    required this.onDimTap,
    required this.onClearFilter,
  });

  final List<DimensionBreakdownItem> breakdownItems;
  final String? activeDimId;
  final Color typeColor;
  final ValueChanged<String> onDimTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    if (breakdownItems.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    // final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.md + 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // "All" chip when a filter is active
            if (activeDimId != null)
              Padding(
                padding: const EdgeInsets.only(left: SpacingTokens.xs),
                child: _FilterPill(
                  label: AppStringsAr.costCenterAllDimensionsFilter,
                  isSelected: false,
                  onTap: onClearFilter,
                  typeColor: scheme.onSurfaceVariant,
                  showClose: true,
                ),
              ),

            ...breakdownItems.map((item) {
              final isSelected = activeDimId == item.dimensionId;
              return Padding(
                padding: const EdgeInsets.only(left: SpacingTokens.xs),
                child: _FilterPill(
                  label: '${item.dimensionName} · ${item.voucherCount}',
                  isSelected: isSelected,
                  onTap: () => onDimTap(item.dimensionId),
                  typeColor: typeColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.typeColor,
    this.showClose = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color typeColor;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = isSelected
        ? typeColor.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = isSelected
        ? typeColor
        : scheme.onSurfaceVariant.withValues(alpha: 0.6);
    final border = isSelected
        ? typeColor.withValues(alpha: 0.25)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showClose) ...[
              Icon(Icons.close_rounded, size: 12, color: fg),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
