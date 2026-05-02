import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/text_sanitizer.dart';

/// RTL-aware text field using [InputDecorationTheme] from [AppTheme].
class QaydTextField extends StatelessWidget {
  const QaydTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.autovalidateMode,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      obscureText: obscureText,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textAlign: TextAlign.start,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: [
        FilteringTextInputFormatter.deny(TextSanitizer.emojiRegex,
            replacementString: ' '),
        ...?inputFormatters,
      ],
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );

    final isLtrType = keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
        keyboardType == const TextInputType.numberWithOptions(signed: true) ||
        keyboardType == TextInputType.phone ||
        keyboardType == TextInputType.emailAddress ||
        keyboardType == TextInputType.url;

    if (isLtrType) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: field,
      );
    }

    return field;
  }
}
