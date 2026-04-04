import 'package:flutter/foundation.dart';

enum SyncEventType {
  claim,
  acceptance,
  rejection,
  journalEntry,
  attachmentSync,    // Blob reference + wrapped voucher key
  collateralSync,    // Encrypted collateral data
  collateralUpdate,  // Re-evaluation event
  unknown;

  static SyncEventType fromString(String val) {
    return SyncEventType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SyncEventType.unknown,
    );
  }
}

@immutable
class SyncNode {
  const SyncNode({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.eventType,
    required this.encryptedPayload,
    required this.syncState,
    this.clientTimestamp,
  });

  /// Unique client-generated UUID for the node
  final String id;
  
  /// Counterpart who sent it
  final int senderId;
  
  /// User who the payload is targeted at
  final int receiverId;

  /// Strongly typed event discriminator
  final SyncEventType eventType;

  /// Opaque encrypted string
  final String encryptedPayload;

  /// Sync state: 'pending', 'delivered', 'read'
  final String syncState;

  final DateTime? clientTimestamp;

  factory SyncNode.fromJson(Map<String, dynamic> json) {
    return SyncNode(
      id: json['id'] as String,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      eventType: SyncEventType.fromString(json['event_type'] as String),
      encryptedPayload: json['encrypted_payload'] as String,
      syncState: json['sync_state'] as String,
      clientTimestamp: json['client_timestamp'] != null
          ? DateTime.tryParse(json['client_timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'event_type': eventType.name,
      'encrypted_payload': encryptedPayload,
      'sync_state': syncState,
      'client_timestamp': clientTimestamp?.toIso8601String(),
    };
  }
}
