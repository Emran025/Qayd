import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as picker;
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/data/models/country_model.dart';
import 'package:qayd/core/constants/countries_names.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';
import 'package:qayd/presentation/widgets/country_picker_dialog.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

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
  String? _errorText;
  final picker.FlutterNativeContactPicker _contactPicker =
      picker.FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry;

    // If a zone code is already present in the controller, try to find the matching country.
    if (selectedCountry == null && widget.zoneController.text.isNotEmpty) {
      final normalizedInput =
          widget.zoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      try {
        selectedCountry = countries.firstWhere(
          (c) =>
              c.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '') ==
              normalizedInput,
        );
      } catch (_) {}
    }

    // Default to Yemen (YE) if no initial country or zone code was provided.
    if (selectedCountry == null && widget.zoneController.text.isEmpty) {
      try {
        selectedCountry = countries.firstWhere((c) => c.status == 'YE');
      } catch (_) {
        if (countries.isNotEmpty) selectedCountry = countries.first;
      }
    }

    if (selectedCountry != null && widget.zoneController.text.isEmpty) {
      widget.zoneController.text =
          selectedCountry!.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '');
    }

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

  void _onZoneChanged(String val) {
    // Smart Spilling: If the user adds numbers to a already satisfied zone code,
    // move the extra numbers to the beginning of the phone controller and switch focus.
    if (selectedCountry != null) {
      final codeDigits =
          selectedCountry!.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '');
      final inputDigits = val.replaceAll(RegExp(r'[^\d]'), '');

      if (inputDigits.length > codeDigits.length &&
          inputDigits.startsWith(codeDigits)) {
        final extra = inputDigits.substring(codeDigits.length);

        // Prepend extra digits to phone and reset zone to code
        widget.phoneController.text = extra + widget.phoneController.text;
        widget.zoneController.text = codeDigits;

        // Move focus and position cursor after inserted digits
        focusNodes[1].requestFocus();
        widget.phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: extra.length),
        );

        _updateFullNumber();
        _clearError();
        return;
      }
    }

    _findCountryByCode(val);
    _updateFullNumber();
    _clearError();

    // Auto-focus logic: move to phone if the input exactly matches a unique country code
    final normalized = val.replaceAll(RegExp(r'[^\d]'), '');
    if (normalized.length >= 2) {
      final isExactMatch = countries.any(
        (c) =>
            c.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '') == normalized,
      );
      if (isExactMatch) {
        focusNodes[1].requestFocus();
      }
    }
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  Future<void> _pickContact() async {
    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null &&
          contact.phoneNumbers != null &&
          contact.phoneNumbers!.isNotEmpty) {
        final rawPhone = contact.phoneNumbers!.first;
        _applyPhoneNumber(rawPhone);
      }
    } catch (e) {
      // Handle potential errors (e.g. permission denied)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الوصول لجهات الاتصال: $e')),
        );
      }
    }
  }

  void _applyPhoneNumber(String rawPhone) {
    // 1. Sanitize the phone number
    var phone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. Handle international format
    if (phone.startsWith('+')) {
      final digits = phone.substring(1);
      // Try to find the longest matching country code
      CountryModel? bestMatch;
      int bestLen = 0;

      for (var c in countries) {
        final cCode = c.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.startsWith(cCode) && cCode.length > bestLen) {
          bestMatch = c;
          bestLen = cCode.length;
        }
      }

      if (bestMatch != null) {
        setState(() {
          selectedCountry = bestMatch;
          widget.zoneController.text =
              bestMatch!.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '');
          widget.phoneController.text = digits.substring(bestLen);
          widget.onCountryChanged?.call();
        });
      } else {
        // Fallback: just put everything in phone
        widget.phoneController.text = digits;
      }
    } else {
      // If no '+' but starts with 00, treat as international
      if (phone.startsWith('00')) {
        _applyPhoneNumber('+${phone.substring(2)}');
        return;
      }

      // Local format or unknown - if it matches current country's typical length but starts with 0
      // Many countries use '0' as a trunk prefix. We might want to strip it if we are sure.
      // But for now, let's keep it simple.
      widget.phoneController.text = phone;
    }

    _updateFullNumber();
    _clearError();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<QaydCustomColors>();
    final accentColor = customColors?.goldAccent ?? theme.colorScheme.primary;

    final isFocused = focusNodes[0].hasFocus || focusNodes[1].hasFocus;
    final hasError = _errorText != null;

    final activeBorderColor = hasError
        ? theme.colorScheme.error
        : (isFocused
            ? accentColor
            : theme.colorScheme.outline.withValues(alpha: 0.4));
    final activeBorderWidth = (isFocused || hasError) ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: Border.all(
                color: activeBorderColor,
                width: activeBorderWidth,
              ),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            TextSanitizer.emojiRegex,
                            replacementString: ' '),
                      ],
                      buildCounter: (
                        _, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) =>
                          null,
                      decoration: const InputDecoration(
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      onChanged: _onZoneChanged,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            TextSanitizer.emojiRegex,
                            replacementString: ' '),
                      ],
                      buildCounter: (
                        _, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) =>
                          null,
                      onChanged: (val) {
                        _updateFullNumber();
                        _clearError();
                      },
                      validator: (val) {
                        String? error;
                        if (selectedCountry == null) {
                          error = AppStrings.youMustSelectThe;
                        } else if (val == null || val.isEmpty) {
                          error = AppStrings.phoneNumberRequired;
                        }

                        // Update local error state to change border color
                        if (error != _errorText) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _errorText = error);
                          });
                        }
                        return error;
                      },
                      decoration: InputDecoration(
                        hintText: widget.label,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                    ),
                  ),
                ),

                // Contact Picker Button
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: _pickContact,
                    icon: Icon(
                      Icons.contact_phone_outlined,
                      color: accentColor.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    tooltip: AppStrings.chooseFromContacts,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Text(
              _errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  void _findCountryByCode(String code) {
    if (code.isEmpty) return;
    final normalizedInput = code.replaceAll(RegExp(r'[^\d]'), '');
    try {
      final country = countries.firstWhere(
        (c) =>
            c.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '') ==
            normalizedInput,
      );
      if (selectedCountry != country) {
        setState(() {
          selectedCountry = country;
        });
        widget.onCountryChanged?.call();
      }
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
            widget.zoneController.text =
                country.countryCallingCode.replaceAll(RegExp(r'[^\d]'), '');
            widget.onCountryChanged?.call();
            _updateFullNumber();
            _clearError();
            focusNodes[1].requestFocus();
          });
        },
        isCollingCode: true,
      ),
    );
  }
}
