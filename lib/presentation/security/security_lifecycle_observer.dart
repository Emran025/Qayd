import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/security/security_cubit.dart';

/// Forwards [WidgetsBindingObserver] lifecycle events to [SecurityCubit].
final class SecurityLifecycleObserver extends StatefulWidget {
  const SecurityLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  State<SecurityLifecycleObserver> createState() =>
      _SecurityLifecycleObserverState();
}

class _SecurityLifecycleObserverState extends State<SecurityLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<SecurityCubit>().onAppLifecycle(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
