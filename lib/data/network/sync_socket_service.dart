import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

/// A service managing the live WebSocket connection for Real-Time Event Broadcasting.
/// Connects securely to the routing server channel.
class SyncSocketService {
  SyncSocketService({required this.wsUrl, required this.tokenProvider});

  final String wsUrl;
  final String? Function() tokenProvider;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _nodeStreamController = StreamController<SyncNode>.broadcast();

  /// Stream of instantly pushed encrypted event nodes from counterparts
  Stream<SyncNode> get incomingNodes => _nodeStreamController.stream;

  /// Connects to the Laravel WebSocket socket (Using Reverb/Custom port).
  Future<void> connect(int currentUserId) async {
    disconnect();
    
    final token = tokenProvider();
    if (token == null) return;

    try {
      final uri = Uri.parse('$wsUrl?token=\$token');
      _channel = WebSocketChannel.connect(uri);

      // Authenticate to private channel
      _channel?.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {
          'auth': token,
          'channel': 'private-user.sync.$currentUserId'
        }
      }));

      _subscription = _channel?.stream.listen(
        (message) {
          try {
            final payload = jsonDecode(message);
            // Ignore pusher internal events
            if (payload['event'] == 'sync.node.dispatched') {
               final data = payload['data']; // The SyncNode JSON
               final node = SyncNode.fromJson(data);
               _nodeStreamController.add(node);
            }
          } catch (e) {
            debugPrint('Error parsing socket message: $e');
          }
        },
        onError: (e) {
          debugPrint('Socket error: $e');
          _reconnect(currentUserId);
        },
        onDone: () {
          _reconnect(currentUserId);
        },
      );
    } catch (e) {
      debugPrint('Connection error: $e');
      _reconnect(currentUserId);
    }
  }

  void _reconnect(int currentUserId) {
    disconnect();
    // In production, add exponential backoff
    Future.delayed(const Duration(seconds: 5), () {
      connect(currentUserId);
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
