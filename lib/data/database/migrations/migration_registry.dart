import 'package:qayd/data/database/migrations/migration_001.dart';
import 'package:qayd/data/database/migrations/migration_002_voucher_fts.dart';
import 'package:qayd/data/database/migrations/migration_003_message_templates.dart';
import 'package:qayd/data/database/migrations/migration_004_notification_messages.dart';
import 'package:qayd/data/database/migrations/migration_005_notification_messages_suggestion_columns.dart';
import 'package:qayd/data/database/migrations/migration_006.dart';
import 'package:qayd/data/database/migrations/migration_007_party_details.dart';
import 'package:qayd/data/database/migrations/migration_008_voucher_signatures.dart';
import 'package:qayd/data/database/migrations/migration_009_imported_signatures.dart';
import 'package:qayd/data/database/migrations/migration_010_tripartite_transfer.dart';
import 'package:qayd/data/database/migrations/migration_011_default_accounts.dart';
import 'package:qayd/data/database/migrations/migration_012_currency_is_active.dart';
import 'package:qayd/data/database/migrations/migration_013_transaction_fees.dart';
import 'package:qayd/data/database/migrations/migration_014_attachments.dart';
import 'package:qayd/data/database/migrations/migration_015_collaterals.dart';
import 'package:qayd/data/database/migrations/migration_016_counterparty_keys.dart';
import 'package:qayd/data/database/migrations/migration_017_threaded_interactions.dart';
import 'package:qayd/data/database/migrations/migration_018_outbox.dart';
import 'package:qayd/data/database/migrations/migration_019_sync_watermarks.dart';
import 'package:qayd/data/database/migrations/migration_020_cost_centers.dart';
import 'package:qayd/data/database/migrations/migration_021_remittance.dart';
import 'package:qayd/data/database/migrations/migration_022_personal_economy_upgrade.dart';
import 'package:qayd/data/database/migrations/migration_023_fix_fts_triggers.dart';
import 'package:qayd/data/database/migrations/migration_024_audit_logs.dart';
import 'package:qayd/data/database/migrations/migration_025_account_archive.dart';
import 'package:qayd/data/database/migrations/migration_026_account_default_cost_centers.dart';
import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Ordered migrations; [applyFromTo] runs `up` for versions in (from, to].
final class MigrationRegistry {
  MigrationRegistry._();

  static final List<SchemaMigration> _all = [
    Migration001(),
    Migration002VoucherFts(),
    Migration003MessageTemplates(),
    Migration004NotificationMessages(),
    Migration005NotificationMessagesSuggestionColumns(),
    Migration006(),
    Migration007PartyDetails(),
    Migration008VoucherSignatures(),
    Migration009ImportedSignatures(),
    Migration010TripartiteTransfer(),
    Migration011DefaultAccounts(),
    Migration012CurrencyIsActive(),
    Migration013TransactionFees(),
    Migration014Attachments(),
    Migration015Collaterals(),
    Migration016CounterpartyKeys(),
    Migration017ThreadedInteractions(),
    Migration018Outbox(),
    Migration019SyncWatermarks(),
    Migration020CostCenters(),
    Migration021Remittance(),
    Migration022PersonalEconomyUpgrade(),
    Migration023FixFtsTriggers(),
    Migration024AuditLogs(),
    Migration025AccountArchive(),
    Migration026AccountDefaultCostCenters(),
  ];

  static List<SchemaMigration> get ordered {
    final copy = [..._all];
    copy.sort((a, b) => a.version.compareTo(b.version));
    return List.unmodifiable(copy);
  }

  static Future<void> applyFromTo(
    Database db, {
    required int fromVersion,
    required int toVersion,
  }) async {
    for (final m in ordered) {
      if (m.version > fromVersion && m.version <= toVersion) {
        await m.up(db);
      }
    }
  }
}
