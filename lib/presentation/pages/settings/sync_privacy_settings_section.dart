import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/pages/settings/sync_privacy_cubit.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Settings page for managing sync privacy policy.
///
/// Allows users to choose their sync mode (open / blocklist / allowlist)
/// and manage the corresponding access list.
class SyncPrivacySettingsSection extends StatefulWidget {
  const SyncPrivacySettingsSection({super.key});

  @override
  State<SyncPrivacySettingsSection> createState() =>
      _SyncPrivacySettingsSectionState();
}

class _SyncPrivacySettingsSectionState
    extends State<SyncPrivacySettingsSection> {
  late final SyncPrivacyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SyncPrivacyCubit(
      identityRepository: InjectionContainer.identityRepository,
      accountRepository: InjectionContainer.accountRepository,
    );
    _cubit.addListener(_onStateChange);
    _cubit.loadPolicy();
  }

  @override
  void dispose() {
    _cubit.removeListener(_onStateChange);
    _cubit.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    setState(() {});

    final state = _cubit.state;
    if (state.error != null) {
      final theme = Theme.of(context);
      final isInternetError = state.error!.contains(AppStrings.internetConnectionFailed) ||
          state.error!.contains('SocketException');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isInternetError
                    ? Icons.cloud_off_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(child: Text(state.error!)),
            ],
          ),
          backgroundColor: isInternetError
              ? Colors.orange.shade800
              : theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(SpacingTokens.md),
        ),
      );
      _cubit.clearMessages();
    }
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.successMessage!)),
      );
      _cubit.clearMessages();
    }
  }

  Future<void> _openMultiAccountPicker(String listType) async {
    final state = _cubit.state;
    final policy = state.policy;
    if (policy == null) return;

    final currentEntries =
        listType == 'block' ? policy.blockList : policy.allowList;

    // Resolve existing accounts to pre-select them
    final initialSelectedIds = currentEntries
        .map((e) => e.localAccountId)
        .whereType<String>()
        .toList();

    if (!mounted) return;

    final selected = await showMultiAccountPickerSheet(
      context,
      listAccounts: InjectionContainer.listAccountsUseCase,
      allowedClassifications: ['receivables', 'payables'],
      initialSelectedIds: initialSelectedIds,
      showIdentityStatus: true,
    );

    if (selected != null && mounted) {
      _cubit.syncListWithAccounts(
        selectedAccounts: selected,
        listType: listType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _cubit.state;
    final policy = state.policy;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.syncPrivacy),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              children: [
                // ── Header Banner ─────────────────────────────────────
                _buildHeaderBanner(context),

                SizedBox(height: SpacingTokens.lg),

                // ── Policy Mode Selection ─────────────────────────────
                _buildSectionLabel(context, AppStrings.privacyMode),
                SizedBox(height: SpacingTokens.sm),

                for (final mode in SyncPolicyMode.values)
                  _PolicyModeCard(
                    mode: mode,
                    isSelected: policy?.mode == mode,
                    isUpdating: state.isUpdating,
                    onTap: () => _cubit.updatePolicyMode(mode),
                  ),

                // ── Access List ────────────────────────────────────────
                if (policy != null &&
                    (policy.mode == SyncPolicyMode.openWithBlocklist ||
                     policy.mode == SyncPolicyMode.closedWithAllowlist)) ...[
                  SizedBox(height: SpacingTokens.lg),
                  _buildSectionLabel(
                    context,
                    policy.mode == SyncPolicyMode.openWithBlocklist
                        ? AppStrings.blockList
                        : AppStrings.allowList,
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  Text(
                    policy.mode == SyncPolicyMode.openWithBlocklist
                        ? AppStrings.usersBlockedFromSyncing
                        : AppStrings.onlyUsersAllowedTo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.md),

                  // Manage list trigger
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: state.isUpdating
                          ? null
                          : () {
                              final listType = policy.mode ==
                                      SyncPolicyMode.openWithBlocklist
                                  ? 'block'
                                  : 'allow';
                              _openMultiAccountPicker(listType);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.group_add_outlined, size: 20),
                      label: Text(
                        policy.mode == SyncPolicyMode.openWithBlocklist
                            ? AppStrings.manageBlockList
                            : AppStrings.manageTheAllowList,
                      ),
                    ),
                  ),

                  SizedBox(height: SpacingTokens.md),

                  // List entries
                  if (_relevantEntries(policy).isEmpty)
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.person_off_outlined,
                                size: 40, color: colorScheme.onSurfaceVariant),
                            SizedBox(height: SpacingTokens.sm),
                            Text(
                              AppStrings.theListIsEmpty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      _relevantEntries(policy).length,
                      (i) {
                        final entry = _relevantEntries(policy)[i];
                        return _AccessListTile(
                          entry: entry,
                          onRemove: () => _cubit.removeEntry(entry.id),
                          isUpdating: state.isUpdating,
                        );
                      },
                    ),
                ],

                SizedBox(height: SpacingTokens.lg),

                // Info box
                _buildInfoBanner(context),
                SizedBox(height: SpacingTokens.xl),
              ],
            ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm, right: 4),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    final theme = Theme.of(context);
    final tertiaryColor = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm + 2,
      ),
      decoration: BoxDecoration(
        color: tertiaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tertiaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tertiaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: tertiaryColor,
              size: 18,
            ),
          ),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.synchronizationControl,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tertiaryColor,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  AppStrings.determineWhoCanSync,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:  EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: theme.colorScheme.tertiary),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              AppStrings.syncingViaDirectQr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<SyncAccessEntry> _relevantEntries(SyncPrivacyPolicy policy) {
    if (policy.mode == SyncPolicyMode.openWithBlocklist) {
      return policy.blockList;
    }
    if (policy.mode == SyncPolicyMode.closedWithAllowlist) {
      return policy.allowList;
    }
    return [];
  }
}

// ── Policy Mode Card ──────────────────────────────────────────────────────────

class _PolicyModeCard extends StatelessWidget {
  const _PolicyModeCard({
    required this.mode,
    required this.isSelected,
    required this.isUpdating,
    required this.onTap,
  });

  final SyncPolicyMode mode;
  final bool isSelected;
  final bool isUpdating;
  final VoidCallback onTap;

  IconData get _icon => switch (mode) {
        SyncPolicyMode.open => Icons.lock_open_outlined,
        SyncPolicyMode.openWithBlocklist => Icons.block_outlined,
        SyncPolicyMode.closedWithAllowlist => Icons.verified_user_outlined,
        SyncPolicyMode.openToContacts => Icons.people_outline_rounded,
        SyncPolicyMode.closed => Icons.lock_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isUpdating ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.tertiary.withValues(alpha: 0.2)
                  : theme.dividerColor.withValues(alpha: 0.05),
            ),
          ),
          child: RadioListTile<SyncPolicyMode>.adaptive(
            value: mode,
            groupValue: isSelected ? mode : null,
            onChanged: isUpdating ? null : (_) => onTap(),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                color: theme.colorScheme.primary,
                size: 19,
              ),
            ),
            title: Text(
              mode.displayNameAr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            subtitle: Text(
              mode.descriptionAr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            activeColor: theme.colorScheme.tertiary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            dense: true,
          ),
        ),
      ),
    );
  }
}

void _inviteByPhone(String name, String phone) {
  final message = AppStrings.appInvitationMessage(name);

  final uri = Uri.parse(
      'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
  launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ── Access List Tile ──────────────────────────────────────────────────────────

class _AccessListTile extends StatelessWidget {
  const _AccessListTile({
    required this.entry,
    required this.onRemove,
    required this.isUpdating,
  });

  final SyncAccessEntry entry;
  final VoidCallback onRemove;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin:  EdgeInsets.only(bottom: SpacingTokens.xs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: entry.listType == 'block'
              ? colorScheme.errorContainer.withValues(alpha: 0.5)
              : colorScheme.primaryContainer.withValues(alpha: 0.5),
          child: Icon(
            entry.listType == 'block'
                ? Icons.block
                : Icons.check_circle_outline,
            color: entry.listType == 'block'
                ? colorScheme.error
                : colorScheme.primary,
            size: 18,
          ),
        ),
        title: Text(
          entry.targetName.isNotEmpty ? entry.targetName : entry.targetPhone,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
        ),
        subtitle: entry.targetUserId == null
            ? Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.targetPhone.isEmpty ? AppStrings.localRecord : AppStrings.notRegistered,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  if (entry.targetPhone.isNotEmpty) ...[
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          _inviteByPhone(entry.targetName, entry.targetPhone),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          AppStrings.callNow,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                entry.targetPhone,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
        trailing: IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            size: 20,
          ),
          onPressed: isUpdating ? null : onRemove,
        ),
      ),
    );
  }
}
