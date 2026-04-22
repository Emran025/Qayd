import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v3: message templates + notification audit log (offline intents).
final class Migration003MessageTemplates implements SchemaMigration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE message_templates (
  id TEXT NOT NULL PRIMARY KEY,
  kind TEXT NOT NULL,
  name TEXT NOT NULL,
  body TEXT NOT NULL,
  is_system INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    await db.execute(
      'CREATE INDEX idx_message_templates_kind ON message_templates (kind)',
    );

    await db.execute('''
CREATE TABLE notification_log (
  id TEXT NOT NULL PRIMARY KEY,
  channel TEXT NOT NULL,
  template_id TEXT,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  rendered_body_preview TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (template_id) REFERENCES message_templates (id) ON DELETE SET NULL
)
''');
    await db.execute(
      'CREATE INDEX idx_notification_log_created ON notification_log (created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_notification_log_entity ON notification_log (entity_type, entity_id)',
    );

    const t = '2026-01-01T00:00:00.000Z';

    await db.execute('''
INSERT INTO message_templates (id, kind, name, body, is_system, sort_order, created_at, updated_at)
VALUES (
  'tpl_sys_receipt',
  'receipt',
  'قبض — قالب افتراضي',
  'عزيزي {{customer}}،\nنحيطكم علماً بأنه تم استلام مبلغ {{amount}} في سند {{type}} رقم: {{voucher_id}} بتاريخ {{date}}.\nالمرسل: {{sender_party}}\nالمستلم: {{receiver_party}}\nالبيان: {{description}}\nالتوثيق: {{signature}}\n— نظام قيد',
  1,
  0,
  '$t',
  '$t'
)
''');

    await db.execute('''
INSERT INTO message_templates (id, kind, name, body, is_system, sort_order, created_at, updated_at)
VALUES (
  'tpl_sys_payment',
  'payment',
  'صرف — قالب افتراضي',
  'عزيزي {{customer}}،\nنحيطكم علماً بأنه تم خصم مبلغ {{amount}} في سند {{type}} رقم: {{voucher_id}} بتاريخ {{date}}.\nالمرسل: {{sender_party}}\nالمستلم: {{receiver_party}}\nالبيان: {{description}}\nالتوثيق: {{signature}}\n— نظام قيد',
  1,
  0,
  '$t',
  '$t'
)
''');

    await db.execute('''
INSERT INTO message_templates (id, kind, name, body, is_system, sort_order, created_at, updated_at)
VALUES (
  'tpl_sys_account',
  'account_balance',
  'رصيد حساب — قالب افتراضي',
  'تفاصيل الحساب: {{account_name}}\nالرصيد الحالي: {{balance}}\nطبيعة الحساب: {{nature}}\nمعرّف الحساب: {{account_id}}\n— قيد',
  1,
  0,
  '$t',
  '$t'
)
''');
  }
}
