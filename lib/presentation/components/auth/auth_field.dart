import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';

/// Standardised text field for auth screens (frosted-glass style).
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.accentColor,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  /// Focus-ring accent color. Defaults to [ColorTokens.emerald500].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? ColorTokens.emerald500;
    final borderColor = ColorTokens.slate200.withValues(alpha: 0.18);
    final style = const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
    ).copyWith(color: Theme.of(context).colorScheme.onSurface);

    final field = TextFormField(
      controller: controller,
      style: style,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      inputFormatters: [
        FilteringTextInputFormatter.deny(TextSanitizer.emojiRegex, replacementString: ' '),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        border: _border(borderColor),
        enabledBorder: _border(borderColor),
        focusedBorder: _border(accent.withValues(alpha: 0.7), width: 1.5),
        errorBorder: _border(ColorTokens.errorSoft.withValues(alpha: 0.7)),
        focusedErrorBorder:
            _border(ColorTokens.errorSoft.withValues(alpha: 0.9), width: 1.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
}
