import 'dart:convert';
import 'dart:io';

import 'package:qayd/domain/entities/audit_entry.dart';

/// formalized reasons for sync packet generation.
enum SyncPacketReason {
  /// Initial data dump when a new device is paired.
  initialBootstrap,

  /// Real-time propagation of a single new audit entry.
  liveEvent,

  /// Background catch-up for missed or failed entries.
  backgroundCatchUp,

  /// Manually triggered full synchronization.
  manualForce;

  String get label => switch (this) {
        SyncPacketReason.initialBootstrap => 'INITIAL_BOOTSTRAP',
        SyncPacketReason.liveEvent => 'LIVE_EVENT',
        SyncPacketReason.backgroundCatchUp => 'BACKGROUND_CATCHUP',
        SyncPacketReason.manualForce => 'MANUAL_FORCE',
      };
}

/// Service responsible for compressing and auditing sync packets.
///
/// §P-5: Compression is mandatory for audit batches to reduce bandwidth
/// consumption during initial device pairing/bootstrap.
class AuditSyncCompressionService {
  const AuditSyncCompressionService();

  /// Compresses a list of [AuditEntry]s into a GZIP-encoded byte array.
  List<int> compressBatch(List<AuditEntry> entries,
      {SyncPacketReason reason = SyncPacketReason.liveEvent}) {
    final entriesJson =
        utf8.encode(jsonEncode(entries.map((e) => e.toMap()).toList()));
    return gzip.encode(entriesJson);
  }
}
