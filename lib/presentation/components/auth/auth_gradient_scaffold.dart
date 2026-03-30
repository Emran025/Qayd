import 'package:flutter/material.dart';

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
