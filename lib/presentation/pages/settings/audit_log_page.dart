import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
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

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showLoadingOverlay = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QaydScaffold(
      appBar: QaydAppBar(title: AppStrings.digitalAuditLog),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuditLogCubit, AuditLogState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage &&
                current.errorMessage != null,
            listener: (context, state) {
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
            },
          ),
          BlocListener<AuditLogCubit, AuditLogState>(
            listenWhen: (previous, current) =>
                previous.isExecutingOperation != current.isExecutingOperation,
            listener: (_, state) {
              if (!mounted) return;
              setState(() => _showLoadingOverlay = state.isExecutingOperation);
            },
          ),
        ],
        child: BlocBuilder<AuditLogCubit, AuditLogState>(
          builder: (context, state) {
            final entries = state.visibleEntries;
            final headId =
                state.allEntries.firstWhere((e) => !e.isUndone, orElse: () {
              return state.allEntries.isNotEmpty
                  ? state.allEntries.first
                  : AuditEntry(
                      id: '',
                      entityType: '',
                      entityId: '',
                      action: AuditAction.create,
                      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                    );
            }).id;

            return Stack(
              children: [
                Column(
                  children: [
                    _AuditFilterHeader(
                      state: state,
                      searchController: _searchController,
                    ),
                    Expanded(
                      child: _buildBody(
                        context: context,
                        theme: theme,
                        state: state,
                        entries: entries,
                        headId: headId,
                      ),
                    ),
                  ],
                ),
                if (_showLoadingOverlay)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ThemeData theme,
    required AuditLogState state,
    required List<AuditEntry> entries,
    required String headId,
  }) {
    if (state.isLoading && state.allEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.isEmpty) return _buildEmptyState(theme);
    if (entries.isEmpty) return _buildNoResultsState(theme);

    return RefreshIndicator(
      onRefresh: () => context.read<AuditLogCubit>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final previous = index > 0 ? entries[index - 1] : null;
          final next = index < entries.length - 1 ? entries[index + 1] : null;

          return _TimelineTile(
            entry: entry,
            isFirst: index == 0,
            isLast: index == entries.length - 1,
            isHead: entry.id == headId && !entry.isUndone,
            sameBatchAsPrevious: _sameBatch(previous, entry),
            sameBatchAsNext: _sameBatch(entry, next),
            allEntries: state.allEntries,
          );
        },
      ),
    );
  }

  bool _sameBatch(AuditEntry? left, AuditEntry? right) {
    if (left == null || right == null) return false;
    if (left.batchId == null || left.batchId!.isEmpty) return false;
    return left.batchId == right.batchId;
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 62,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: SpacingTokens.md),
          QaydText(
            AppStrings.thereAreNoTransactions,
            slot: QaydTextStyleSlot.titleMedium,
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
            size: 62,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: SpacingTokens.md),
          QaydText(
            AppStrings.auditNoMatchesForFilter,
            slot: QaydTextStyleSlot.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _AuditFilterHeader extends StatelessWidget {
  const _AuditFilterHeader({
    required this.state,
    required this.searchController,
  });

  final AuditLogState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 1,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.md,
          SpacingTokens.sm,
          SpacingTokens.md,
          SpacingTokens.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        context.read<AuditLogCubit>().applyFilter(
                              state.filter.copyWith(searchQuery: value.trim()),
                            ),
                    decoration: InputDecoration(
                      hintText: AppStrings.auditSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                _FilterButton(state: state),
                if (state.filter.isActive) ...[
                  const SizedBox(width: SpacingTokens.xs),
                  IconButton(
                    onPressed: () {
                      searchController.clear();
                      context.read<AuditLogCubit>().clearFilter();
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    tooltip: AppStrings.allLabel,
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.state});
  final AuditLogState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters = state.filter.action != null ||
        state.filter.severity != null ||
        !state.filter.showReverted;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: () => _showFilterSheet(context),
          icon: const Icon(Icons.tune_rounded),
          tooltip: AppStrings.filterLedger,
        ),
        if (hasActiveFilters)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    final cubit = context.read<AuditLogCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.lg)),
      ),
      builder: (context) {
        return BlocBuilder<AuditLogCubit, AuditLogState>(
          bloc: cubit,
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                SpacingTokens.md,
                SpacingTokens.md,
                SpacingTokens.md,
                MediaQuery.of(context).viewInsets.bottom + SpacingTokens.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      QaydText(
                        AppStrings.filterLedger,
                        slot: QaydTextStyleSlot.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => cubit.clearFilter(),
                        child: Text(AppStrings.allLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  QaydText(
                    AppStrings.actionLabel,
                    slot: QaydTextStyleSlot.labelLarge,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChipItem<AuditAction>(
                        label: AppStrings.addition,
                        value: AuditAction.create,
                        groupValue: state.filter.action,
                        onSelected: (val) => cubit.applyFilter(state.filter
                            .copyWith(action: val, clearAction: val == null)),
                      ),
                      _FilterChipItem<AuditAction>(
                        label: AppStrings.amendment,
                        value: AuditAction.update,
                        groupValue: state.filter.action,
                        onSelected: (val) => cubit.applyFilter(state.filter
                            .copyWith(action: val, clearAction: val == null)),
                      ),
                      _FilterChipItem<AuditAction>(
                        label: AppStrings.withdrawdelete,
                        value: AuditAction.delete,
                        groupValue: state.filter.action,
                        onSelected: (val) => cubit.applyFilter(state.filter
                            .copyWith(action: val, clearAction: val == null)),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  QaydText(
                    AppStrings.appearanceThemeMode, // Should be severity label but using existing
                    slot: QaydTextStyleSlot.labelLarge,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChipItem<AuditSeverity>(
                        label: AppStrings.auditSeverityInfo,
                        value: AuditSeverity.info,
                        groupValue: state.filter.severity,
                        onSelected: (val) => cubit.applyFilter(state.filter
                            .copyWith(
                                severity: val, clearSeverity: val == null)),
                      ),
                      _FilterChipItem<AuditSeverity>(
                        label: AppStrings.auditSeverityWarning,
                        value: AuditSeverity.warning,
                        groupValue: state.filter.severity,
                        onSelected: (val) => cubit.applyFilter(state.filter
                            .copyWith(
                                severity: val, clearSeverity: val == null)),
                      ),
                      _FilterChipItem<AuditSeverity>(
                        label: AppStrings.auditSeverityCritical,
                        value: AuditSeverity.critical,
                        groupValue: state.filter.severity,
                        onSelected: (val) => cubit.applyFilter(state.filter
                            .copyWith(
                                severity: val, clearSeverity: val == null)),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: QaydText(
                      AppStrings.showRevertedOperations,
                      slot: QaydTextStyleSlot.bodyMedium,
                    ),
                    trailing: Switch.adaptive(
                      value: state.filter.showReverted,
                      onChanged: (val) =>
                          cubit.applyFilter(state.filter.copyWith(showReverted: val)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChipItem<T> extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(selected ? null : value),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.isHead,
    required this.sameBatchAsPrevious,
    required this.sameBatchAsNext,
    required this.allEntries,
  });

  final AuditEntry entry;
  final bool isFirst;
  final bool isLast;
  final bool isHead;
  final bool sameBatchAsPrevious;
  final bool sameBatchAsNext;
  final List<AuditEntry> allEntries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUndone = entry.isUndone;
    final actionColor = isUndone
        ? theme.colorScheme.outline
        : switch (entry.action) {
            AuditAction.create => Colors.green,
            AuditAction.update => Colors.blue,
            AuditAction.delete => Colors.red,
            AuditAction.revert => Colors.orange,
          };

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      decoration: BoxDecoration(
        color: entry.batchId != null
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : null,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(sameBatchAsPrevious ? 6 : RadiusTokens.md),
          topRight: Radius.circular(sameBatchAsPrevious ? 6 : RadiusTokens.md),
          bottomLeft: Radius.circular(sameBatchAsNext ? 6 : RadiusTokens.md),
          bottomRight: Radius.circular(sameBatchAsNext ? 6 : RadiusTokens.md),
        ),
      ),
      padding: const EdgeInsets.all(SpacingTokens.xs),
      child: Opacity(
        opacity: isUndone ? 0.4 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  _TimelineLineSegment(
                    hidden: isFirst,
                    isDashed: isUndone,
                    color: theme.colorScheme.primary,
                  ),
                  Container(
                    width: isHead ? 18 : 14,
                    height: isHead ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHead ? theme.colorScheme.primary : actionColor,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: isHead
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  _TimelineLineSegment(
                    hidden: isLast,
                    isDashed: isUndone,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Expanded(
              child: _AuditEntryCard(
                entry: entry,
                isHead: isHead,
                actionColor: actionColor,
                allEntries: allEntries,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineLineSegment extends StatelessWidget {
  const _TimelineLineSegment({
    required this.hidden,
    required this.isDashed,
    required this.color,
  });

  final bool hidden;
  final bool isDashed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox(height: 22);
    if (!isDashed) {
      return Container(
        width: 2.5,
        height: 22,
        color: color.withValues(alpha: 0.6),
      );
    }
    return SizedBox(
      width: 2.5,
      height: 22,
      child: CustomPaint(painter: _DashedLinePainter(color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 2;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
          Offset(size.width / 2, y), Offset(size.width / 2, y + 3.5), paint);
      y += 6.5;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AuditEntryCard extends StatelessWidget {
  const _AuditEntryCard({
    required this.entry,
    required this.isHead,
    required this.actionColor,
    required this.allEntries,
  });

  final AuditEntry entry;
  final bool isHead;
  final Color actionColor;
  final List<AuditEntry> allEntries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = intl.DateFormat('yyyy/MM/dd - HH:mm:ss');

    return Card(
      elevation: isHead ? 3 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        side: BorderSide(
          color: isHead
              ? theme.colorScheme.primary
              : entry.isUndone
                  ? theme.colorScheme.outline.withValues(alpha: 0.3)
                  : actionColor.withValues(alpha: 0.35),
          width: isHead ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.xs,
        ),
        initiallyExpanded: isHead,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          child: Icon(_actionIcon(entry.action), color: actionColor, size: 18),
        ),
        title: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _entityBadge(context, _getEntityName(entry.entityType)),
            QaydText(
              '${_getActionName(entry.action)} ${_getEntityName(entry.entityType)}',
              slot: QaydTextStyleSlot.titleSmall,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                decoration: entry.isUndone ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              QaydText(
                dateFormat.format(entry.createdAt),
                slot: QaydTextStyleSlot.labelSmall,
              ),
              _severityBadge(context, entry.severity),
              if (entry.isUndone)
                _statusBadge(context, AppStrings.cancellation,
                    Theme.of(context).colorScheme.error),
              if (isHead)
                _statusBadge(context, AppStrings.currentStatus,
                    Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          SpacingTokens.md,
          0,
          SpacingTokens.md,
          SpacingTokens.sm,
        ),
        children: [
          _idRow(theme),
          const SizedBox(height: SpacingTokens.sm),
          if (entry.cleanOldData != null)
            _dataBlock(
              context: context,
              label: AppStrings.previousCase,
              data: entry.cleanOldData!,
              isNew: false,
            ),
          if (entry.cleanOldData != null && entry.cleanNewData != null)
            const SizedBox(height: SpacingTokens.sm),
          if (entry.cleanNewData != null)
            _dataBlock(
              context: context,
              label: AppStrings.newStatus,
              data: entry.cleanNewData!,
              isNew: true,
            ),
          const SizedBox(height: SpacingTokens.sm),
          _actionsRow(context),
        ],
      ),
    );
  }

  Widget _idRow(ThemeData theme) {
    return Row(
      children: [
        QaydText(
          AppStrings.referenceId,
          slot: QaydTextStyleSlot.labelSmall,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
            child: QaydText(
              entry.entityId,
              slot: QaydTextStyleSlot.labelSmall,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataBlock({
    required BuildContext context,
    required String label,
    required Map<String, dynamic> data,
    required bool isNew,
  }) {
    final theme = Theme.of(context);
    final cleaned = _transformMetadata(data);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isNew
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),
        border: Border.all(
          color: isNew
              ? Colors.green.withValues(alpha: 0.25)
              : Colors.red.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QaydText(label, slot: QaydTextStyleSlot.labelSmall),
          const SizedBox(height: 6),
          ...cleaned.entries.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_translateKey(item.key)}: ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: _translateValue(item.key, item.value),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (!entry.isUndone)
          OutlinedButton.icon(
            icon: const Icon(Icons.undo_rounded, size: 16),
            onPressed: () => _handleRevertSingle(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber.shade800,
            ),
            label: Text(AppStrings.auditRevertSingle),
          ),
        if (!entry.isUndone)
          TextButton.icon(
            icon: const Icon(Icons.history_rounded, size: 16),
            onPressed: () => _confirmRollbackTo(context),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            label: Text(AppStrings.backToThisPoint),
          ),
        if (entry.isUndone)
          OutlinedButton.icon(
            icon: const Icon(Icons.redo_rounded, size: 16),
            onPressed: () => _handleRedoSingle(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            label: Text(AppStrings.restoreOnlyThis),
          ),
        if (entry.isUndone)
          TextButton.icon(
            icon: const Icon(Icons.fast_forward_rounded, size: 16),
            onPressed: () => _confirmRedoTo(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            label: Text(AppStrings.restoration),
          ),
      ],
    );
  }

  Future<void> _handleRevertSingle(BuildContext context) async {
    final cubit = context.read<AuditLogCubit>();
    final impacted = await cubit.loadImpactedEntries(entry.id);
    if (!context.mounted) return;
    if (impacted.isEmpty) {
      QaydDialog.show(
        context: context,
        icon: Icons.undo_rounded,
        iconColor: Colors.amber.shade800,
        title: AppStrings.auditRevertSingleTitle,
        content: AppStrings.auditRevertSingleBody,
        primaryActionLabel: AppStrings.auditRevertSingleConfirm,
        onPrimaryAction: () {
          Navigator.of(context).pop();
          cubit.revertSingleEntry(entry.id);
        },
        secondaryActionLabel: AppStrings.cancellation,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ImpactWarningDialog(
        impactedEntries: impacted,
        targetEntryId: entry.id,
      ),
    );
    cubit.clearImpact();
  }

  Future<void> _handleRedoSingle(BuildContext context) async {
    final cubit = context.read<AuditLogCubit>();
    final related = allEntries
        .where((e) =>
            e.batchId != null &&
            e.batchId == entry.batchId &&
            e.id != entry.id &&
            e.isUndone)
        .toList();
    if (related.isEmpty) {
      QaydDialog.show(
        context: context,
        icon: Icons.redo_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        title: AppStrings.confirmRedoOperations,
        content: AppStrings.systematicRedoExplainer,
        primaryActionLabel: AppStrings.restoreOnlyThis,
        onPrimaryAction: () {
          Navigator.pop(context);
          cubit.redoSingleEntry(entry.id);
        },
        secondaryActionLabel: AppStrings.cancellation,
      );
      return;
    }

    final group = [...related, entry]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final oldest = group.first;
    QaydDialog.show(
      context: context,
      icon: Icons.layers_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: AppStrings.confirmRedoOperations,
      content: AppStrings.redoImpactWarning(group
          .map((e) =>
              '- ${_getEntityName(e.entityType)} • ${_getActionName(e.action)}')
          .join('\n')),
      primaryActionLabel: AppStrings.restoreAll,
      onPrimaryAction: () {
        Navigator.pop(context);
        cubit.redoTo(oldest.id);
      },
      secondaryActionLabel: AppStrings.restoreOnlyThis,
      onSecondaryAction: () {
        Navigator.pop(context);
        cubit.redoSingleEntry(entry.id);
      },
    );
  }

  void _confirmRollbackTo(BuildContext context) {
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

  void _confirmRedoTo(BuildContext context) {
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

  Widget _entityBadge(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(RadiusTokens.xs),
      ),
      child: QaydText(
        text,
        slot: QaydTextStyleSlot.labelSmall,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _severityBadge(BuildContext context, AuditSeverity severity) {
    final label = switch (severity) {
      AuditSeverity.info => AppStrings.auditSeverityInfo,
      AuditSeverity.warning => AppStrings.auditSeverityWarning,
      AuditSeverity.critical => AppStrings.auditSeverityCritical,
    };
    final color = switch (severity) {
      AuditSeverity.info => Colors.blue,
      AuditSeverity.warning => Colors.orange,
      AuditSeverity.critical => Colors.red,
    };
    return _statusBadge(context, label, color);
  }

  Widget _statusBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.xs),
      ),
      child: QaydText(
        text,
        slot: QaydTextStyleSlot.labelSmall,
        color: color,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  IconData _actionIcon(AuditAction action) {
    return switch (action) {
      AuditAction.create => Icons.add_task_rounded,
      AuditAction.update => Icons.published_with_changes_rounded,
      AuditAction.delete => Icons.delete_sweep_rounded,
      AuditAction.revert => Icons.settings_backup_restore_rounded,
    };
  }

  Map<String, dynamic> _transformMetadata(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result.remove('root_account_id');
    result.remove('parent_id');
    return result;
  }

  // Keep helper methods intact.
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
      'currency' => AppStrings.auditEntityCurrency,
      'currencies' => AppStrings.auditEntityCurrencies,
      'accrual_component' => AppStrings.auditEntityAccrual,
      'accrual_components' => AppStrings.auditEntityAccruals,
      'accrual' => AppStrings.auditEntityAccrual,
      'accruals' => AppStrings.auditEntityAccruals,
      'cost_center_dimension' => AppStrings.auditEntityCostCenterDimension,
      'cost_center_dimensions' => AppStrings.auditEntityCostCenterDimensions,
      'transaction_fee' => AppStrings.auditEntityTransactionFee,
      'transaction_fees' => AppStrings.auditEntityTransactionFees,
      'transaction_fee_setting' => AppStrings.auditEntityTransactionFee,
      'transaction_fee_settings' => AppStrings.auditEntityTransactionFees,
      'message_template' => AppStrings.auditEntityMessageTemplate,
      'message_templates' => AppStrings.auditEntityMessageTemplates,
      'party_details' => AppStrings.auditEntityPartyDetails,
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
      'currency_code' => AppStrings.auditFieldCode,
      'state' => AppStrings.theCondition,
      'is_active' => AppStrings.auditFieldIsActive,
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
      'code' => AppStrings.auditFieldCode,
      'symbol' => AppStrings.auditFieldSymbol,
      'decimal_places' => AppStrings.auditFieldDecimalPlaces,
      'exchange_rate' => AppStrings.auditFieldExchangeRate,
      'is_base' => AppStrings.auditFieldIsBase,
      'total_amount_minor' => AppStrings.auditFieldTotalAmountMinor,
      'frequency' => AppStrings.auditFieldFrequency,
      'start_date' => AppStrings.auditFieldStartDate,
      'next_due_date' => AppStrings.auditFieldNextDueDate,
      'source_account_id' => AppStrings.auditFieldSourceAccountId,
      'destination_account_id' => AppStrings.auditFieldDestinationAccountId,
      'category_id' => AppStrings.auditFieldCategoryId,
      'cost_center_id' => AppStrings.auditFieldCostCenterId,
      'kind' => AppStrings.auditFieldKind,
      'body' => AppStrings.auditFieldBody,
      'is_system' => AppStrings.auditFieldIsSystem,
      'sort_order' => AppStrings.auditFieldSortOrder,
      'collateral_value_minor' => AppStrings.auditFieldCollateralValueMinor,
      'revaluation_date' => AppStrings.auditFieldRevaluationDate,
      'voucher_id' => AppStrings.auditFieldVoucherId,
      'settled_at' => AppStrings.auditFieldSettledAt,
      'due_date' => AppStrings.auditFieldDueDate,
      'collateral_type' => AppStrings.auditFieldCollateralType,
      'budget_minor_units' => AppStrings.auditFieldBudgetMinorUnits,
      'center_type' => AppStrings.auditFieldCenterType,
      'debit_minor' => AppStrings.auditFieldDebitMinor,
      'credit_minor' => AppStrings.auditFieldCreditMinor,
      'ledger_id' => AppStrings.auditFieldLedgerId,
      'entry_date' => AppStrings.auditFieldEntryDate,
      'voucher_entry_id' => AppStrings.auditFieldVoucherEntryId,
      'value' => AppStrings.auditFieldValue,
      'calc_type' => AppStrings.auditFieldCalculationType,
      'calculation_type' => AppStrings.auditFieldCalculationType,
      _ => key,
    };
  }

  String _translateValue(String key, dynamic value) {
    if (value == null) return '';
    final valStr = value.toString();

    String minorToReadable(String raw) {
      final parsed = int.tryParse(raw);
      if (parsed == null) return raw;
      return (parsed / 100.0).toStringAsFixed(2);
    }

    bool isTruthy(String v) => v == '1' || v.toLowerCase() == 'true';

    return switch (key) {
      'type' => switch (valStr.toLowerCase()) {
          'root' => AppStrings.accountTypeRoot,
          'child' => AppStrings.accountTypeChild,
          'payment' => AppStrings.voucherTypePayment,
          'receipt' => AppStrings.voucherTypeReceipt,
          _ => valStr,
        },
      'is_active' ||
      'is_base' ||
      'is_system' =>
        isTruthy(valStr) ? AppStrings.active : AppStrings.deactivated,
      'state' => switch (valStr.toLowerCase()) {
          'draft' => AppStrings.statusDraft,
          'confirmed' => AppStrings.statusConfirmed,
          'settled' => AppStrings.statusSettled,
          'voided' => AppStrings.statusVoided,
          'pending' => AppStrings.statusPending,
          _ => valStr,
        },
      'currency' || 'currency_code' => CurrencyUtil.getSymbol(valStr),
      'classification' => ClassificationUtil.getLocalizedGroupName(valStr),
      'total_amount_minor' ||
      'collateral_value_minor' ||
      'budget_minor_units' ||
      'debit_minor' ||
      'credit_minor' =>
        minorToReadable(valStr),
      'frequency' => switch (valStr.toLowerCase()) {
          'daily' => AppStrings.auditFrequencyDaily,
          'weekly' => AppStrings.auditFrequencyWeekly,
          'monthly' => AppStrings.auditFrequencyMonthly,
          'quarterly' => AppStrings.auditFrequencyQuarterly,
          'semi_annually' ||
          'semiannually' =>
            AppStrings.auditFrequencySemiAnnually,
          'yearly' || 'annually' => AppStrings.auditFrequencyYearly,
          'once' => AppStrings.auditFrequencyOnce,
          _ => valStr,
        },
      'calc_type' || 'calculation_type' => switch (valStr.toLowerCase()) {
          'fixed' => AppStrings.auditCalcTypeFixed,
          'percentage' => AppStrings.auditCalcTypePercentage,
          _ => valStr,
        },
      _ => valStr,
    };
  }
}

class _ImpactWarningDialog extends StatelessWidget {
  const _ImpactWarningDialog({
    required this.impactedEntries,
    required this.targetEntryId,
  });

  final List<AuditEntry> impactedEntries;
  final String targetEntryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = intl.DateFormat('yyyy/MM/dd - HH:mm');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: QaydText(
                    AppStrings.auditImpactWarningTitle,
                    slot: QaydTextStyleSlot.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            QaydText(
              AppStrings.auditImpactWarningBody,
              slot: QaydTextStyleSlot.bodySmall,
            ),
            const SizedBox(height: SpacingTokens.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
              ),
              child: QaydText(
                '${impactedEntries.length} ${AppStrings.auditImpactAffectedCount}',
                slot: QaydTextStyleSlot.labelSmall,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: impactedEntries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = impactedEntries[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.entityType} - ${item.action.label}'),
                    subtitle: Text(dateFormat.format(item.createdAt)),
                  );
                },
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.cancellation),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AuditLogCubit>().revertSingleEntry(
                            targetEntryId,
                          );
                    },
                    child: Text(AppStrings.auditImpactWarningProceed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
