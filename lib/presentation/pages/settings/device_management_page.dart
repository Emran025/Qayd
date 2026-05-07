import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/sync/device_pairing_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/sync/device_pairing_qr_scanner_page.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  late final DevicePairingCubit _cubit;
  String _deviceName = AppStrings.deviceDefaultName;

  @override
  void initState() {
    super.initState();
    _cubit = DevicePairingCubit(
      facade: InjectionContainer.devicePairingFacade,
    )..load();
    _cubit.addListener(_onCubitChanged);
    _initDeviceName();
  }

  Future<void> _initDeviceName() async {
    final name = await InjectionContainer.hardwareIdService.obtainDeviceName();
    if (mounted) {
      setState(() => _deviceName = name);
    }
  }

  @override
  void dispose() {
    _cubit.removeListener(_onCubitChanged);
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

  Future<void> _scanAndLinkCompanion() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DevicePairingQrScannerPage()),
    );
    if (scanned == null || scanned.isEmpty) return;
    await _cubit.sendCompanionBootstrap(
      scannedQr: scanned,
      approvalGate: () async {
        if (!mounted) return false;
        final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Link new companion device?'),
            content: const Text(
              'Approve to securely transfer encrypted login bootstrap credentials.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Approve'),
              ),
            ],
          ),
        );
        return approved ?? false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _cubit.state;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.deviceManagement),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.devicePairingQrOnlyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.devicePairingQrOnlyDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.important_devices_rounded),
                    title: Text(AppStrings.deviceDefaultName),
                    subtitle: Text(
                      _deviceName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isSaving ? null : _scanAndLinkCompanion,
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Scan Companion QR'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.pairedDevices,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: state.isLoading ? null : _cubit.load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.devicePairingRefresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.info_outline_rounded),
              hintText: AppStrings.devicePairingPublicKeysAuto,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.sessions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppStrings.devicePairingNoDevicesYet,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...state.sessions.map(
              (s) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      s.isCurrent
                          ? Icons.phone_android_rounded
                          : Icons.devices_other_rounded,
                    ),
                  ),
                  title: Text(s.deviceName ?? s.deviceId),
                  subtitle: Text(
                    '${AppStrings.lastSyncSeq}: ${s.lastSyncSeq}'
                    '${s.isCurrent ? AppStrings.devicePairingThisDeviceSuffix : ''}',
                  ),
                  trailing: s.isActive
                      ? TextButton(
                          onPressed: () => _cubit.revoke(s.deviceId),
                          child: Text(AppStrings.revoke),
                        )
                      : Text(AppStrings.revoked),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
