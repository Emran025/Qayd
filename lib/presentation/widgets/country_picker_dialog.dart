import 'dart:async';
import 'dart:ui';

import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:qayd/data/models/country_model.dart';
import 'package:qayd/core/constants/countries_names.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';

class CountryPickerDialog extends StatefulWidget {
  final CountryModel? initialCountry;
  final ValueChanged<CountryModel> onCountrySelected;
  final bool isCollingCode;

  const CountryPickerDialog({
    super.key,
    this.initialCountry,
    required this.onCountrySelected,
    required this.isCollingCode,
  });

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<CountryModel> _filtered;
  late FocusNode _focusNode;
  CountryModel? _tempSelected;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filtered = countries;
    _tempSelected = widget.initialCountry;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filtered = countries
            .where((c) =>
                c.arabicName.contains(query) ||
                c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<QaydCustomColors>();
    final accentColor = customColors?.goldAccent ?? theme.colorScheme.primary;

    return StatefulBuilder(
      builder: (context, setState) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
            ),
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(SpacingTokens.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                constraints: const BoxConstraints(maxHeight: 550),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.public, color: accentColor),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(
                          'تحديد الدولة',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      style: theme.textTheme.bodyLarge,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "ابحث عن الدولة (بالعربية أو الإنجليزية)",
                        prefixIcon: Icon(Icons.search,
                            color: theme.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                        child: ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.1),
                            height: 1,
                          ),
                          itemBuilder: (_, i) {
                            final country = _filtered[i];
                            final isSelected = _tempSelected?.id == country.id;
                            return RadioListTile<CountryModel>(
                              value: country,
                              groupValue: _tempSelected,
                              activeColor: accentColor,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              title: Text(
                                country.arabicName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? accentColor
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                country.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.isCollingCode)
                                    Text(
                                      "+${country.countryCallingCode}",
                                      textDirection: TextDirection.ltr,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: isSelected
                                            ? accentColor
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Flag.fromString(
                                    country.status,
                                    height: 20,
                                    width: 30,
                                  ),
                                ],
                              ),
                              onChanged: (sel) => setState(() {
                                _tempSelected = sel;
                                _searchCtrl.text = sel?.arabicName ?? "";
                                _focusNode.unfocus();
                              }),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("إلغاء"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            onPressed: _tempSelected == null
                                ? null
                                : () {
                                    widget.onCountrySelected(_tempSelected!);
                                    Navigator.pop(context);
                                  },
                            child: const Text("تأكيد"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
