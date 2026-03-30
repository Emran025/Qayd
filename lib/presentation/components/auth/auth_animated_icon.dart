import 'package:flutter/material.dart';

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

// ── Animated vault/shield icon ───────────────────────────────────────────────

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
