import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

class AuthAdminBadge extends StatelessWidget {
  const AuthAdminBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ColorTokens.goldAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorTokens.goldAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: ColorTokens.goldAccent,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
