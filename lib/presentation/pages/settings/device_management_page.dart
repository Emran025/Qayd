import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/sync/device_pairing_cubit.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  late final DevicePairingCubit _cubit;
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = DevicePairingCubit(
      sessionRepository: InjectionContainer.deviceSessionRepository,
      pairingService: InjectionContainer.devicePairingService,
    )..load();
    _cubit.addListener(_onCubitChanged);
  }

  @override
  void dispose() {
    _cubit.removeListener(_onCubitChanged);
    _nameController.dispose();
    _idController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _onCubitChanged() {
    if (!mounted) return;
    setState(() {});
    final state = _cubit.state;
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    } else if (state.success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.success!)),
      );
    }
  }

  Future<void> _pair() async {
    await _cubit.pair(
      deviceId: _idController.text.trim(),
      deviceName: _nameController.text.trim(),
      publicKeyHex: _keyController.text.trim(),
    );
    _idController.clear();
    _nameController.clear();
    _keyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = _cubit.state;
    return Scaffold(
      appBar: QaydAppBar(title: 'Device Management'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Device Name'),
          ),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(labelText: 'Device ID'),
          ),
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(labelText: 'Public Key (hex)'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isSaving ? null : _pair,
            child: Text(state.isSaving ? 'Pairing...' : 'Pair Device'),
          ),
          const SizedBox(height: 16),
          const Text('Paired devices'),
          const SizedBox(height: 8),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ...state.sessions.map(
              (s) => Card(
                child: ListTile(
                  title: Text(s.deviceName ?? s.deviceId),
                  subtitle: Text('Last seq: ${s.lastSyncSeq}'),
                  trailing: s.isActive
                      ? TextButton(
                          onPressed: () => _cubit.revoke(s.deviceId),
                          child: const Text('Revoke'),
                        )
                      : const Text('Revoked'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
