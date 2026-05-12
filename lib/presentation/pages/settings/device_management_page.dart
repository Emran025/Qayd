import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/components/atomic/qayd_empty_state.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/sync/device_pairing_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/sync/device_pairing_qr_scanner_page.dart';
import 'package:qayd/presentation/sync/manual_code_display_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  late final DevicePairingCubit _cubit;
  String _deviceName = AppStrings.deviceDefaultName;
  bool _isCompanionDevice = false;

  @override
  void initState() {
    super.initState();
    _cubit = DevicePairingCubit(
      facade: InjectionContainer.devicePairingFacade,
    )..load();
    _cubit.addListener(_onCubitChanged);
    _initDeviceName();
    _loadDeviceRole();
  }

  Future<void> _initDeviceName() async {
    final name = await InjectionContainer.hardwareIdService.obtainDeviceName();
    if (mounted) {
      setState(() => _deviceName = name);
    }
  }

  Future<void> _loadDeviceRole() async {
    final isCompanion =
        await InjectionContainer.licenseVault.isCompanionDevice();
    if (!mounted) return;
    setState(() => _isCompanionDevice = isCompanion);
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
        final approved = await QaydDialog.show<bool>(
          context: context,
          icon: Icons.link_rounded,
          title: AppStrings.linkNewCompanionDevicePrompt,
          content: AppStrings.linkNewCompanionDeviceDesc,
          secondaryActionLabel: AppStrings.actionCancel,
          onSecondaryAction: () => Navigator.of(context).pop(false),
          primaryActionLabel: AppStrings.actionApprove,
          onPrimaryAction: () => Navigator.of(context).pop(true),
        );
        return approved ?? false;
      },
    );
  }

  Future<void> _showManualLinkCode() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualCodeDisplayPage(
          onBootstrapSent: () {
            Navigator.of(context).pop();
            _cubit.load();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompanionDevice) {
      return Scaffold(
        appBar: QaydAppBar(title: AppStrings.deviceManagement),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: QaydText(
              AppStrings.companionDeviceRestriction,
              slot: QaydTextStyleSlot.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final state = _cubit.state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return QaydScaffold(
      appBar: QaydAppBar(title: AppStrings.deviceManagement),
      body: RefreshIndicator(
        onRefresh: () async => _cubit.load(),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.lg,
          ),
          children: [
            // --- Current Device Profile ---
            _buildCurrentDeviceProfile(scheme, theme),

            const SizedBox(height: SpacingTokens.xl),

            // --- Pairing Actions Section ---
            if (!_isCompanionDevice) ...[
              _buildSectionTitle(AppStrings.devicePairingQrOnlyTitle),
              const SizedBox(height: SpacingTokens.sm),
              QaydText(
                AppStrings.devicePairingQrOnlyDesc,
                slot: QaydTextStyleSlot.labelSmall,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: SpacingTokens.md),
              _buildActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: AppStrings.scanCompanionQr,
                onTap: state.isSaving ? null : _scanAndLinkCompanion,
                color: ColorTokens.emerald500,
              ),
              const SizedBox(height: SpacingTokens.sm),
              _buildActionCard(
                icon: Icons.dialpad_rounded,
                title: AppStrings.manualCodeLinkButton,
                onTap: state.isSaving ? null : _showManualLinkCode,
                color: scheme.primary,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: scheme.primary),
                    const SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: QaydText(
                        AppStrings.companionDeviceRestriction,
                        slot: QaydTextStyleSlot.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: SpacingTokens.xl),

            // --- Paired Devices List ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(AppStrings.pairedDevices),
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _cubit.load,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: AppStrings.devicePairingRefresh,
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),

            if (state.sessions.isEmpty && !state.isLoading)
              QaydEmptyState(
                icon: Icons.phonelink_off_rounded,
                title: AppStrings.devicePairingNoDevicesYet,
              )
            else
              ...state.sessions.map((s) => _buildPairedDeviceTile(s, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDeviceProfile(ColorScheme scheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.9),
            scheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.important_devices_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: SpacingTokens.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QaydText(
                  AppStrings.deviceDefaultName,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                QaydText(
                  _deviceName,
                  slot: QaydTextStyleSlot.titleLarge,
                  color: Colors.white,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: QaydText(
                    AppStrings.deviceRolePrimaryLabel,
                    slot: QaydTextStyleSlot.labelSmall,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return QaydText(
      title,
      slot: QaydTextStyleSlot.titleSmall,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: QaydText(
                title,
                slot: QaydTextStyleSlot.bodyMedium,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: ColorTokens.slate400),
          ],
        ),
      ),
    );
  }

  Widget _buildPairedDeviceTile(dynamic s, ColorScheme scheme) {
    final isCurrent = s.isCurrent;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isCurrent
              ? scheme.primary.withValues(alpha: 0.1)
              : scheme.surfaceContainerHighest,
          child: Icon(
            isCurrent
                ? Icons.phone_android_rounded
                : Icons.devices_other_rounded,
            color: isCurrent ? scheme.primary : ColorTokens.slate400,
            size: 20,
          ),
        ),
        title: QaydText(
          s.deviceName ?? s.deviceId,
          slot: QaydTextStyleSlot.bodyMedium,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: QaydText(
          '${AppStrings.lastSyncSeq}: ${s.lastSyncSeq}'
          '${isCurrent ? ' (${AppStrings.devicePairingThisDeviceSuffix})' : ''}',
          slot: QaydTextStyleSlot.labelSmall,
        ),
        trailing: s.isActive
            ? TextButton(
                onPressed: isCurrent ? null : () => _cubit.revoke(s.deviceId),
                child: QaydText(
                  AppStrings.revoke,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: isCurrent ? scheme.outline : scheme.error,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : QaydText(
                AppStrings.revoked,
                slot: QaydTextStyleSlot.labelSmall,
                color: ColorTokens.slate400,
              ),
      ),
    );
  }
}
