import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// Full-width submit button for auth forms.
///
/// Shows a spinner when [loading] is `true`.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  /// Button fill color. Defaults to [ColorTokens.emerald500].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fillColor = color ?? ColorTokens.emerald500;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: fillColor,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
