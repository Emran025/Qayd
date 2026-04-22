import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/pages/settings/sync_privacy_cubit.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

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
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = SyncPrivacyCubit(
      identityRepository: InjectionContainer.identityRepository,
    );
    _cubit.addListener(_onStateChange);
    _cubit.loadPolicy();
  }

  @override
  void dispose() {
    _cubit.removeListener(_onStateChange);
    _cubit.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    setState(() {});

    final state = _cubit.state;
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
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

  @override
  Widget build(BuildContext context) {
    final state = _cubit.state;
    final policy = state.policy;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: QaydAppBar(title: 'خصوصية المزامنة'),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              children: [
                // ── Header Banner ─────────────────────────────────────
                _buildHeaderBanner(context),

                const SizedBox(height: SpacingTokens.lg),

                // ── Policy Mode Selection ─────────────────────────────
                _buildSectionLabel(context, 'وضع الخصوصية'),
                const SizedBox(height: SpacingTokens.sm),

                for (final mode in SyncPolicyMode.values)
                  _PolicyModeCard(
                    mode: mode,
                    isSelected: policy?.mode == mode,
                    isUpdating: state.isUpdating,
                    onTap: () => _cubit.updatePolicyMode(mode),
                  ),

                // ── Access List ────────────────────────────────────────
                if (policy != null && policy.mode != SyncPolicyMode.open) ...[
                  const SizedBox(height: SpacingTokens.lg),
                  _buildSectionLabel(
                    context,
                    policy.mode == SyncPolicyMode.openWithBlocklist
                        ? 'قائمة الحظر'
                        : 'قائمة السماح',
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    policy.mode == SyncPolicyMode.openWithBlocklist
                        ? 'المستخدمون المحظورون من المزامنة معك.'
                        : 'المستخدمون المسموح فقط لهم بالمزامنة معك.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.md),

                  // Add entry input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: '+966...',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      FilledButton.icon(
                        onPressed: state.isUpdating
                            ? null
                            : () {
                                final phone = _phoneController.text.trim();
                                if (phone.isEmpty) return;
                                final listType = policy.mode ==
                                        SyncPolicyMode.openWithBlocklist
                                    ? 'block'
                                    : 'allow';
                                _cubit.addToList(
                                    phone: phone, listType: listType);
                                _phoneController.clear();
                              },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('إضافة'),
                      ),
                    ],
                  ),

                  const SizedBox(height: SpacingTokens.md),

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
                            const SizedBox(height: SpacingTokens.sm),
                            Text(
                              'القائمة فارغة',
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

                const SizedBox(height: SpacingTokens.lg),

                // Info box
                _buildInfoBanner(context),
                const SizedBox(height: SpacingTokens.xl),
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
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التحكم بالمزامنة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tertiaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'حدد من يمكنه مزامنة السندات معك واكتشاف مفتاحك العام.',
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
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: theme.colorScheme.tertiary),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              'المزامنة عبر مسح باركود QR مباشرة تعتبر موافقة صريحة وتتجاوز هذه الإعدادات.',
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
    return policy.mode == SyncPolicyMode.openWithBlocklist
        ? policy.blockList
        : policy.allowList;
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
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
        color: colorScheme.error,
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: entry.listType == 'block'
                ? colorScheme.errorContainer
                : colorScheme.primaryContainer,
            child: Icon(
              entry.listType == 'block'
                  ? Icons.block
                  : Icons.check_circle_outline,
              color: entry.listType == 'block'
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: Text(
            entry.targetName.isNotEmpty ? entry.targetName : entry.targetPhone,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: entry.targetName.isNotEmpty
              ? Text(
                  entry.targetPhone,
                  style: Theme.of(context).textTheme.bodySmall,
                  textDirection: TextDirection.ltr,
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: isUpdating ? null : onRemove,
            tooltip: 'حذف',
          ),
        ),
      ),
    );
  }
}
