import 'package:flutter/material.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// A crimson-tinted inline error notice for auth forms.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorTokens.errorDeep.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorTokens.errorSoft.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Cairo',
          color: const Color(0xFFFCA5A5), // red-300
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
