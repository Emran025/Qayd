import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

// ── Animated vault/shield icon ───────────────────────────────────────────────

/// A pulsing circle icon used at the top of auth screens.
///
/// The [iconData], [iconColor], and optional [size] control the appearance.
class AuthAnimatedIcon extends StatefulWidget {
  const AuthAnimatedIcon({
    super.key,
    required this.iconData,
    required this.iconColor,
    this.size = 88,
    this.pulseDuration = const Duration(milliseconds: 2000),
  });

  final IconData iconData;
  final Color iconColor;
  final double size;
  final Duration pulseDuration;

  @override
  State<AuthAnimatedIcon> createState() => _AuthAnimatedIconState();
}

class _AuthAnimatedIconState extends State<AuthAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.pulseDuration)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.91, end: 1.09).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.iconColor.withValues(alpha: 0.12),
          border: Border.all(
            color: widget.iconColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(
          widget.iconData,
          size: widget.size * 0.5,
          color: widget.iconColor,
        ),
      ),
    );
  }
}

// ── Frosted-glass text field ─────────────────────────────────────────────────

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
    final style = GoogleFonts.cairo(fontSize: 14, color: ColorTokens.slate50);

    return TextFormField(
      controller: controller,
      style: style,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(color: ColorTokens.slate400),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        suffixIcon: suffixIcon,
        errorStyle: GoogleFonts.cairo(fontSize: 12),
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
  }

  OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
}

// ── Error banner ─────────────────────────────────────────────────────────────

/// A crimson-tinted inline error notice for auth forms.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorTokens.errorDeep.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorTokens.errorSoft.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        message,
        style: GoogleFonts.cairo(
          fontSize: 13,
          color: const Color(0xFFFCA5A5), // red-300
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Full-width submit button ─────────────────────────────────────────────────

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

// ── Admin-only badge ─────────────────────────────────────────────────────────

/// A pill badge indicating an admin-restricted area.
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

// ── Dark gradient scaffold ────────────────────────────────────────────────────

/// Wraps [child] in the standard auth-screen slate-950 gradient scaffold.
class AuthGradientScaffold extends StatelessWidget {
  const AuthGradientScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020617), // slate-950
              Color(0xFF0A1628), // navy-950
              Color(0xFF020617),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

// ── Password toggle suffix icon ───────────────────────────────────────────────

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

// ── Step progress dots ────────────────────────────────────────────────────────

/// Animated pill-shaped step indicator.
class StepProgressDot extends StatelessWidget {
  const StepProgressDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active
            ? ColorTokens.emerald500
            : ColorTokens.slate400.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── Auth page title block ─────────────────────────────────────────────────────

/// Standardised title + subtitle centred text block for auth pages.
class AuthTitleBlock extends StatelessWidget {
  const AuthTitleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ColorTokens.slate50,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: subtitleColor ?? ColorTokens.slate400,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
