import 'package:flutter/material.dart';

/// Wraps [child] in the standard auth-screen slate-950 gradient scaffold.
class AuthGradientScaffold extends StatelessWidget {
  const AuthGradientScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surfaceContainerLow,
                Theme.of(context).colorScheme.surfaceContainerHigh,
                Theme.of(context).colorScheme.surfaceContainerLow,
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
