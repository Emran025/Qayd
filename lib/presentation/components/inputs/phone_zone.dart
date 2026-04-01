import 'dart:ui';

import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/data/models/country_model.dart';
import 'package:qayd/core/constants/countries_names.dart';
import 'package:qayd/presentation/widgets/country_picker_dialog.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class PhoneZoneForm extends StatefulWidget {
  final TextEditingController zoneController;
  final TextEditingController phoneController;
  final CountryModel? initialCountry;
  final String label;
  final VoidCallback? onCountryChanged;
  final ValueChanged<String>? onFullNumberChanged;

  const PhoneZoneForm({
    super.key,
    required this.zoneController,
    required this.phoneController,
    this.initialCountry,
    required this.label,
    this.onCountryChanged,
    this.onFullNumberChanged,
  });

  @override
  State<PhoneZoneForm> createState() => _PhoneZoneFormState();
}

class _PhoneZoneFormState extends State<PhoneZoneForm> {
  CountryModel? selectedCountry;
  final List<FocusNode> focusNodes = [FocusNode(), FocusNode()];

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry;

    // Default to Yemen (YE) if no initial country or zone code was provided.
    if (selectedCountry == null && widget.zoneController.text.isEmpty) {
      try {
        selectedCountry = countries.firstWhere((c) => c.status == 'YE');
      } catch (_) {
        // Fallback to first country if Yemen is not found for some reason.
        if (countries.isNotEmpty) selectedCountry = countries.first;
      }
    }

    if (selectedCountry != null && widget.zoneController.text.isEmpty) {
      widget.zoneController.text = selectedCountry!.countryCallingCode
          .replaceAll(' ', '');
    }

    // Add focus listeners to update the border color when fields gain focus.
    for (var node in focusNodes) {
      node.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (var node in focusNodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    super.dispose();
  }

  void _handleInput(int index) {
    if (index == 0) {
      focusNodes[1].requestFocus();
    } else {
      focusNodes[1].unfocus();
    }
  }

  void _handleKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        index == 1 &&
        widget.phoneController.text.isEmpty) {
      focusNodes[0].requestFocus();
    }
  }

  void _updateFullNumber() {
    final merged = (widget.zoneController.text + widget.phoneController.text)
        .replaceAll(' ', '')
        .replaceAll('+', '');
    widget.onFullNumberChanged?.call(merged);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<QaydCustomColors>();
    final accentColor = customColors?.goldAccent ?? theme.colorScheme.primary;

    final isFocused = focusNodes[0].hasFocus || focusNodes[1].hasFocus;
    final borderColor = isFocused
        ? accentColor
        : theme.colorScheme.outline.withValues(alpha: 0.4);
    final borderWidth = isFocused ? 1.5 : 1.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              children: [
                // Country Selector
                GestureDetector(
                  onTap: _showCountryPicker,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedCountry != null)
                          Flag.fromString(
                            selectedCountry!.status,
                            height: 18,
                            width: 26,
                          )
                        else
                          Icon(
                            Icons.flag_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),

                // Calling Code (+)
                Text(
                  "+",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),

                SizedBox(
                  width: 50,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => _handleKeyEvent(event, 0),
                    child: TextFormField(
                      controller: widget.zoneController,
                      focusNode: focusNodes[0],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      maxLength: 4,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      decoration: const InputDecoration(
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        _findCountryByCode(val);
                        _updateFullNumber();
                        if (val.length >= 3) {
                          _handleInput(0);
                        }
                      },
                    ),
                  ),
                ),

                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),

                // Phone Number Input
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => _handleKeyEvent(event, 1),
                    child: TextFormField(
                      controller: widget.phoneController,
                      focusNode: focusNodes[1],
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyLarge,
                      maxLength: 14,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      decoration: InputDecoration(
                        hintText: widget.label,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        _updateFullNumber();
                      },
                      validator: (val) {
                        if (selectedCountry == null) return "يجب اختيار الدولة";
                        if (val == null || val.isEmpty) {
                          return "رقم الهاتف مطلوب";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _findCountryByCode(String code) {
    if (code.isEmpty) return;
    try {
      final country = countries.firstWhere(
        (c) =>
            c.countryCallingCode.replaceAll(' ', '') ==
            code.replaceAll(' ', ''),
      );
      setState(() {
        selectedCountry = country;
      });
      widget.onCountryChanged?.call();
    } catch (_) {
      // Not found
    }
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (_) => CountryPickerDialog(
        initialCountry: selectedCountry,
        onCountrySelected: (country) {
          setState(() {
            selectedCountry = country;
            widget.zoneController.text = country.countryCallingCode.replaceAll(
              ' ',
              '',
            );
            widget.onCountryChanged?.call();
            _updateFullNumber();
            focusNodes[1].requestFocus();
          });
        },
        isCollingCode: true,
      ),
    );
  }
}
