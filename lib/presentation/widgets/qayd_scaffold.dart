import 'package:flutter/material.dart';
import 'package:qayd/presentation/widgets/settings_sidebar.dart';

/// A centralized Scaffold for the Qayd application that ensures consistent
/// navigation (Sidebar) and theme across all main pages without code duplication.
class QaydScaffold extends StatelessWidget {
  const QaydScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showDrawer = true,
    this.resizeToAvoidBottomInset,
  });

  /// The AppBar for the page. Must be a PreferredSizeWidget.
  final PreferredSizeWidget? appBar;

  /// The main content of the page.
  final Widget body;

  /// Floating Action Button, if any.
  final Widget? floatingActionButton;

  /// Bottom Navigation Bar (used in AppShellPage).
  final Widget? bottomNavigationBar;

  /// Whether to show the SettingsSidebar drawer.
  final bool showDrawer;

  /// Whether to resize the body when the keyboard appears.
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: showDrawer ? const SettingsSidebar() : null,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
