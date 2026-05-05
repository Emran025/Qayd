import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/presentation/utils/classification_util.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/settings/audit_log_cubit.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

import 'package:intl/intl.dart' as intl;

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return QaydScaffold(
      appBar: QaydAppBar(
        title: AppStrings.digitalAuditLog,
      ),
      body: BlocBuilder<AuditLogCubit, AuditLogState>(
        builder: (context, state) {
          if (state.isLoading && state.visibleEntries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isEmpty) {
            return _buildEmptyState(theme);
          }

          return Column(
            children: [
              _buildFilterBar(context, state, theme),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<AuditLogCubit>().load(),
                  child: state.visibleEntries.isEmpty
                      ? _buildNoResultsState(theme)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.md,
                              vertical: SpacingTokens.lg),
                          itemCount: state.visibleEntries.length,
                          itemBuilder: (context, index) {
                            final entry = state.visibleEntries[index];
                            final isFirst = index == 0;
                            final isLast =
                                index == state.visibleEntries.length - 1;
                            final isHead = index == state.headIndex;

                            return _TimelineTile(
                              isFirst: isFirst,
                              isLast: isLast,
                              isHead: isHead,
                              entry: entry,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, AuditLogState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (state.filter.isActive)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => context.read<AuditLogCubit>().clearFilter(),
                  color: theme.colorScheme.error,
                  tooltip: AppStrings.allLabel,
                ),
              ),
            _FilterChip<AuditAction>(
              label: AppStrings.addition,
              value: AuditAction.create,
              groupValue: state.filter.action,
              onSelected: (val) => context.read<AuditLogCubit>().applyFilter(
                  state.filter.copyWith(action: val, clearAction: val == null)),
            ),
            _FilterChip<AuditAction>(
              label: AppStrings.amendment,
              value: AuditAction.update,
              groupValue: state.filter.action,
              onSelected: (val) => context.read<AuditLogCubit>().applyFilter(
                  state.filter.copyWith(action: val, clearAction: val == null)),
            ),
            _FilterChip<AuditAction>(
              label: AppStrings.withdrawdelete,
              value: AuditAction.delete,
              groupValue: state.filter.action,
              onSelected: (val) => context.read<AuditLogCubit>().applyFilter(
                  state.filter.copyWith(action: val, clearAction: val == null)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: SpacingTokens.md),
          QaydText(
            AppStrings.thereAreNoTransactions,
            slot: QaydTextStyleSlot.titleMedium,
          ),
          const SizedBox(height: SpacingTokens.xs),
          QaydText(
            AppStrings.theHistoryOfAll,
            slot: QaydTextStyleSlot.bodySmall,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: SpacingTokens.md),
          QaydText(
            AppStrings.invalidData,
            slot: QaydTextStyleSlot.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          onSelected(selected ? value : null);
        },
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isHead;
  final AuditEntry entry;

  const _TimelineTile({
    required this.isFirst,
    required this.isLast,
    required this.isHead,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUndone = entry.isUndone;
    final color = isUndone
        ? theme.disabledColor
        : _getActionColor(entry.action, theme.colorScheme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Git-like Tree Column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: isUndone ? 2 : 3,
                  height: 24,
                  color: isFirst
                      ? Colors.transparent
                      : (isUndone
                          ? theme.disabledColor.withValues(alpha: 0.5)
                          : theme.colorScheme.primary),
                ),
                Container(
                  width: isHead ? 20 : 16,
                  height: isHead ? 20 : 16,
                  decoration: BoxDecoration(
                    color: isHead ? theme.colorScheme.primary : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 3,
                    ),
                    boxShadow: isHead
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: isUndone ? 2 : 3,
                    color: isLast
                        ? Colors.transparent
                        : (isUndone
                            ? theme.disabledColor.withValues(alpha: 0.5)
                            : theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          // Entry Card
          Expanded(
            child: Opacity(
              opacity: isUndone ? 0.6 : 1.0,
              child:
                  _AuditEntryCard(entry: entry, color: color, isHead: isHead),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(AuditAction action, ColorScheme scheme) {
    return switch (action) {
      AuditAction.create => Colors.green,
      AuditAction.update => Colors.blue,
      AuditAction.delete => Colors.red,
      AuditAction.revert => Colors.orange,
    };
  }
}

class _AuditEntryCard extends StatelessWidget {
  final AuditEntry entry;
  final Color color;
  final bool isHead;

  const _AuditEntryCard(
      {required this.entry, required this.color, required this.isHead});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = intl.DateFormat('yyyy/MM/dd | HH:mm:ss');
    final isUndone = entry.isUndone;

    return Card(
      elevation: isHead ? 4 : 0,
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        side: BorderSide(
          color: isHead
              ? theme.colorScheme.primary
              : (isUndone
                  ? theme.dividerColor.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.3)),
          width: isHead ? 2 : (isUndone ? 1 : 1.5),
        ),
      ),
      color: isUndone
          ? theme.colorScheme.surface.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      child: ExpansionTile(
        initiallyExpanded: isHead,
        tilePadding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md, vertical: SpacingTokens.xs),
        leading: _buildActionIcon(theme),
        title: Row(
          children: [
            _buildTypeBadge(theme),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: QaydText(
                '${_getActionName(entry.action)} ${_getEntityName(entry.entityType)}',
                slot: QaydTextStyleSlot.titleSmall,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isUndone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 12, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: QaydText(dateFormat.format(entry.createdAt),
                        slot: QaydTextStyleSlot.labelSmall,
                        color: theme.colorScheme.onSurfaceVariant,
                        style: TextStyle(
                          decoration:
                              isUndone ? TextDecoration.lineThrough : null,
                        )),
                  ),
                ],
              ),
              if (isUndone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: QaydText(
                    AppStrings.cancellation,
                    slot: QaydTextStyleSlot.labelSmall,
                    color: theme.colorScheme.error,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              if (isHead)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 10, color: theme.colorScheme.primary),
                      const SizedBox(width: 2),
                      QaydText(
                        AppStrings.active,
                        slot: QaydTextStyleSlot.labelSmall,
                        color: theme.colorScheme.primary,
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
        children: [
          _buildDetailsSection(theme),
          if (!isHead) _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
      ),
      child: Icon(
        _getActionIcon(entry.action),
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildTypeBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(RadiusTokens.xs),
      ),
      child: QaydText(
        _getEntityName(entry.entityType),
        slot: QaydTextStyleSlot.labelSmall,
        color: theme.colorScheme.onSecondaryContainer,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    Map<String, dynamic>? cleanOldData = entry.cleanOldData;
    Map<String, dynamic>? cleanNewData = entry.cleanNewData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(RadiusTokens.md)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdRow(theme),
          if (cleanOldData != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildDataPoint(theme, AppStrings.previousCase, cleanOldData),
          ],
          if (cleanNewData != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildDataPoint(theme, AppStrings.newStatus, cleanNewData,
                isNew: true),
          ],
        ],
      ),
    );
  }

  Widget _buildIdRow(ThemeData theme) {
    return Row(
      children: [
        QaydText(AppStrings.referenceId,
            slot: QaydTextStyleSlot.labelSmall,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: QaydText(entry.entityId,
                slot: QaydTextStyleSlot.labelSmall,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDataPoint(
      ThemeData theme, String label, Map<String, dynamic> data,
      {bool isNew = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QaydText(label,
            slot: QaydTextStyleSlot.labelSmall,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isNew
                ? Colors.green.withValues(alpha: 0.05)
                : Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
            border: Border.all(
              color: (isNew ? Colors.green : Colors.red).withValues(alpha: 0.1),
            ),
          ),
          child: Wrap(
            spacing: 8,
            children: _transformMetadata(data)
                .entries
                .map((e) => _buildKeyValue(theme, e.key, e.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _transformMetadata(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    // User requested to hide root account in favor of classification
    result.remove('root_account_id');
    result.remove('parent_id');
    return result;
  }

  Widget _buildKeyValue(ThemeData theme, String key, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${_translateKey(key)}: ',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: _translateValue(key, value),
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (entry.isUndone) {
      return Padding(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _showRedoDialog(context),
              icon: const Icon(Icons.fast_forward_rounded, size: 16),
              label: Text(AppStrings.restoration),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _showRollbackDialog(context),
              icon: const Icon(Icons.history_rounded, size: 16),
              label: Text(AppStrings.backToThisPoint),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getActionIcon(AuditAction action) {
    return switch (action) {
      AuditAction.create => Icons.add_task_rounded,
      AuditAction.update => Icons.published_with_changes_rounded,
      AuditAction.delete => Icons.delete_sweep_rounded,
      AuditAction.revert => Icons.settings_backup_restore_rounded,
    };
  }

  String _getEntityName(String type) {
    return switch (type.toLowerCase()) {
      'account' => AppStrings.account,
      'accounts' => AppStrings.account,
      'voucher' => AppStrings.financialBond,
      'vouchers' => AppStrings.financialBond,
      'collateral' => AppStrings.collateral,
      'collaterals' => AppStrings.collaterals,
      'attachment' => AppStrings.attachment,
      'attachments' => AppStrings.attachments,
      'ledger_entry' => AppStrings.ledgerEntry,
      'ledger_entries' => AppStrings.ledgerEntries,
      'cost_center' => AppStrings.costCenter,
      'cost_centers' => AppStrings.costCenters,
      _ => type,
    };
  }

  String _getActionName(AuditAction action) {
    return switch (action) {
      AuditAction.create => AppStrings.addition,
      AuditAction.update => AppStrings.amendment,
      AuditAction.delete => AppStrings.withdrawdelete,
      AuditAction.revert => AppStrings.restoration,
    };
  }

  String _translateKey(String key) {
    return switch (key) {
      'name' => AppStrings.theName,
      'type' => AppStrings.type,
      'amount' => AppStrings.amount,
      'currency' => AppStrings.currency,
      'state' => AppStrings.theCondition,
      'is_active' => AppStrings.active,
      'confirmed_at' => AppStrings.confirmationDate,
      'classification' => AppStrings.classification,
      'description' => AppStrings.description,
      'notes' => AppStrings.notesLabel,
      'reference_number' => AppStrings.referenceNumber1,
      'affected_account_id' => AppStrings.affectedAccount,
      'counterparty_id' => AppStrings.counterparty,
      'date' => AppStrings.dateLabel,
      'created_at' => AppStrings.creationDate,
      'updated_at' => AppStrings.modificationDate,
      _ => key,
    };
  }

  String _translateValue(String key, dynamic value) {
    if (value == null) return '';
    final valStr = value.toString();

    return switch (key) {
      'type' => switch (valStr.toLowerCase()) {
          'root' => AppStrings.accountTypeRoot,
          'child' => AppStrings.accountTypeChild,
          'payment' => AppStrings.voucherTypePayment,
          'receipt' => AppStrings.voucherTypeReceipt,
          _ => valStr,
        },
      'is_active' => valStr == '1' || valStr.toLowerCase() == 'true'
          ? AppStrings.active
          : AppStrings.deactivated,
      'state' => switch (valStr.toLowerCase()) {
          'draft' => AppStrings.statusDraft,
          'confirmed' => AppStrings.statusConfirmed,
          'settled' => AppStrings.statusSettled,
          'voided' => AppStrings.statusVoided,
          'pending' => AppStrings.statusPending,
          _ => valStr,
        },
      'currency' => CurrencyUtil.getSymbol(valStr),
      'classification' => ClassificationUtil.getLocalizedGroupName(valStr),
      _ => valStr,
    };
  }

  void _showRollbackDialog(BuildContext context) {
    QaydDialog.show(
      context: context,
      icon: Icons.history_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: AppStrings.confirmSystematicReversal,
      content: AppStrings.systematicReversalExplainer,
      primaryActionLabel: AppStrings.confirmRollback,
      onPrimaryAction: () {
        Navigator.pop(context);
        context.read<AuditLogCubit>().rollbackTo(entry.id);
      },
      secondaryActionLabel: AppStrings.cancellation,
    );
  }

  void _showRedoDialog(BuildContext context) {
    QaydDialog.show(
      context: context,
      icon: Icons.fast_forward_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: AppStrings.confirmRedoOperations,
      content: AppStrings.systematicRedoExplainer,
      primaryActionLabel: AppStrings.restoration,
      onPrimaryAction: () {
        Navigator.pop(context);
        context.read<AuditLogCubit>().redoTo(entry.id);
      },
      secondaryActionLabel: AppStrings.cancellation,
    );
  }
}
