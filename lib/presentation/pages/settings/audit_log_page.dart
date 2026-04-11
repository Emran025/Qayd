import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/settings/audit_log_cubit.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';
import 'package:intl/intl.dart' as intl;

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return QaydScaffold(
      appBar: const QaydAppBar(
        title: 'سجل التدقيق الرقمي',
      ),
      body: BlocBuilder<AuditLogCubit, AuditLogState>(
        builder: (context, state) {
          if (state.isLoading && state.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.entries.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<AuditLogCubit>().load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(SpacingTokens.md),
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                return _AuditEntryCard(entry: entry);
              },
            ),
          );
        },
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
          const QaydText(
            'لا توجد عمليات مسجلة في السجل حالياً',
            slot: QaydTextStyleSlot.titleMedium,
          ),
          const SizedBox(height: SpacingTokens.xs),
          QaydText(
            'سيظهر هنا تاريخ كافة الحركات والعمليات التي تقوم بها',
            slot: QaydTextStyleSlot.bodySmall,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _AuditEntryCard extends StatelessWidget {
  final AuditEntry entry;

  const _AuditEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = intl.DateFormat('yyyy/MM/dd | HH:mm:ss');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      color: theme.colorScheme.surface,
      child: ExpansionTile(
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              QaydText(
                dateFormat.format(entry.createdAt),
                slot: QaydTextStyleSlot.labelSmall,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        children: [
          _buildDetailsSection(theme),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionIcon(ThemeData theme) {
    final color = _getActionColor(entry.action, theme.colorScheme);
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
          if (entry.oldData != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildDataPoint(theme, 'الحالة السابقة', entry.oldData!),
          ],
          if (entry.newData != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildDataPoint(theme, 'الحالة الجديدة', entry.newData!,
                isNew: true),
          ],
        ],
      ),
    );
  }

  Widget _buildIdRow(ThemeData theme) {
    return Row(
      children: [
        QaydText('المعرف المرجعي:',
            slot: QaydTextStyleSlot.labelSmall,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: QaydText(entry.entityId,
              slot: QaydTextStyleSlot.labelSmall,
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
            children: data.entries
                .map((e) => _buildKeyValue(theme, e.key, e.value))
                .toList(),
          ),
        ),
      ],
    );
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
              text: '$value',
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
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => _showRollbackDialog(context),
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('تراجع لهذه النقطة'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(AuditAction action) {
    return switch (action) {
      AuditAction.create => Icons.add_task_rounded,
      AuditAction.update => Icons.published_with_changes_rounded,
      AuditAction.delete => Icons.delete_sweep_rounded,
      AuditAction.revert => Icons.settings_backup_restore_rounded,
    };
  }

  Color _getActionColor(AuditAction action, ColorScheme scheme) {
    return switch (action) {
      AuditAction.create => Colors.green,
      AuditAction.update => Colors.blue,
      AuditAction.delete => Colors.red,
      AuditAction.revert => Colors.orange,
    };
  }

  String _getEntityName(String type) {
    return switch (type) {
      'account' => 'حساب',
      'voucher' => 'سند مالي',
      _ => type,
    };
  }

  String _getActionName(AuditAction action) {
    return switch (action) {
      AuditAction.create => 'إضافة',
      AuditAction.update => 'تعديل',
      AuditAction.delete => 'سحب/حذف',
      AuditAction.revert => 'استعادة',
    };
  }

  String _translateKey(String key) {
    return switch (key) {
      'name' => 'الاسم',
      'type' => 'النوع',
      'amount' => 'المبلغ',
      'currency' => 'العملة',
      'state' => 'الحالة',
      'is_active' => 'نشط',
      'confirmed_at' => 'تاريخ التأكيد',
      'classification' => 'التصنيف',
      _ => key,
    };
  }

  void _showRollbackDialog(BuildContext context) {
    // ... existing dialog logic remains or slightly improved
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const QaydText('تأكيد التراجع النظامي',
            slot: QaydTextStyleSlot.titleMedium),
        content: const Text(
            'سيقوم النظام بإلغاء كافة العمليات التي تمت بعد هذه اللحظة الزمنية وإعادة التطبيق إلى حالته حينها. هل ترغب بالمتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuditLogCubit>().rollbackTo(entry.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('تأكيد التراجع'),
          ),
        ],
      ),
    );
  }
}
