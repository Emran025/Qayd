import 'package:flutter/material.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// Eye icon button for password fields.
class PasswordToggleIcon extends StatelessWidget {
  const PasswordToggleIcon({
    super.key,
    required this.obscure,
    required this.onToggle,
  });

  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: ColorTokens.slate400,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}
