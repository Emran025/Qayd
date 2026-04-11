import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';

class AuditLogService {
  final AuditLogRepository auditRepo;
  final AccountRepository accountRepo;
  final VoucherRepository voucherRepo;

  AuditLogService({
    required this.auditRepo,
    required this.accountRepo,
    required this.voucherRepo,
  });

  Future<void> log({
    required String entityType,
    required String entityId,
    required AuditAction action,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    final entry = AuditEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityType: entityType,
      entityId: entityId,
      action: action,
      oldData: oldData,
      newData: newData,
      createdAt: DateTime.now(),
    );
    await auditRepo.save(entry);
  }

  Future<List<AuditEntry>> getQueue() => auditRepo.listAll();

  Future<void> rollbackTo(String auditEntryId) async {
    final allEntries = await auditRepo.listAll(); // Descending order
    final targetIndex = allEntries.indexWhere((e) => e.id == auditEntryId);
    if (targetIndex == -1) return;

    // We revert entries from the latest down TO the target (exclusive, meaning target is the state we want to stay at)
    // Actually, usually "rollback to X" means X is the LAST valid entry.
    final entriesToRevert = allEntries.sublist(0, targetIndex);

    for (final entry in entriesToRevert) {
      await _revertSingle(entry);
    }
    
    // Clean up audit log after rollback? Usually yes, to maintain linear history.
    await auditRepo.deleteAfter(allEntries[targetIndex].createdAt);
  }

  Future<void> _revertSingle(AuditEntry entry) async {
    // This is a placeholder for actual complex logic.
    // In a real app, we'd need entity-specific restoration logic.
    // For now, we'll implement a conceptual "revert".
    print('Reverting ${entry.entityType} ${entry.entityId} (Action: ${entry.action.name})');
    
    if (entry.action == AuditAction.create) {
      // Reverting a CREATE means DELETE.
      // This would require specialized delete methods in repositories.
    } else if (entry.action == AuditAction.update) {
      // Reverting an UPDATE means applying oldData.
    }
  }
}
