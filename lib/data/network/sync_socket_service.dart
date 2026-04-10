import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

/// A service managing the live WebSocket connection for Real-Time Event Broadcasting.
/// Connects securely to the routing server channel using the Pusher protocol.
class SyncSocketService {
  SyncSocketService({
    required this.wsUrl,
    required this.tokenProvider,
    required this.authUrl,
  });

  final String wsUrl;
  final Future<String?> Function() tokenProvider;
  final String authUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final _nodeStreamController = StreamController<SyncNode>.broadcast();
  final _eventStreamController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of instantly pushed encrypted event nodes from counterparts
  Stream<SyncNode> get incomingNodes => _nodeStreamController.stream;

  /// Stream of all raw socket events for external listening (e.g. EmailVerified)
  Stream<Map<String, dynamic>> get socketEvents => _eventStreamController.stream;

  /// Connects to the Laravel WebSocket socket (Using Reverb/Custom port).
  Future<void> connect(int currentUserId) async {
    disconnect();

    final token = await tokenProvider();
    if (token == null) return;

    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      await _channel?.ready;

      _subscription = _channel?.stream.listen(
        (message) async {
          try {
            final payload = jsonDecode(message);
            final eventName = payload['event'];

            // 1. Handle Pusher Connection Established Handshake
            if (eventName == 'pusher:connection_established') {
              final dataString = payload['data'];
              final dataObj = jsonDecode(dataString);
              final socketId = dataObj['socket_id'];

              // Perform HTTP auth for private channel
              final channelName = 'private-user.sync.$currentUserId';

              debugPrint(
                  'Authenticating channel: $channelName for socket: $socketId');

              try {
                final dio = Dio();
                final response = await dio.post(authUrl,
                    data: {
                      'socket_id': socketId,
                      'channel_name': channelName,
                    },
                    options: Options(
                      contentType: Headers.formUrlEncodedContentType,
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest',
                        'Content-Type': 'application/x-www-form-urlencoded',
                      },
                    ));

                final authHash = response.data['auth'];
                debugPrint('Broadcasting Auth Success for $channelName');

                // Authenticate to private channel
                _channel?.sink.add(jsonEncode({
                  'event': 'pusher:subscribe',
                  'data': {'auth': authHash, 'channel': channelName}
                }));

                // Establish ping loop to keep-alive Reverb
                _pingTimer?.cancel();
                _pingTimer = Timer.periodic(const Duration(seconds: 30), (t) {
                  _channel?.sink
                      .add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
                });
              } catch (e) {
                debugPrint('Broadcasting Auth Failed: $e');
              }
            }

            final data = payload['data']; // The SyncNode payload
            // Laravel sometimes double encodes the data if sent via Event
            final dataMap = data is String ? jsonDecode(data) : data;

            _eventStreamController.add({
              'event': eventName,
              'data': dataMap,
              'channel': payload['channel'],
            });

            // Handle SyncNode events
            if (eventName == 'sync.node.dispatched' ||
                eventName == 'App\\Events\\SyncNodeDispatched') {
              final nodeData = dataMap['node'] ?? dataMap;
              final node = SyncNode.fromJson(nodeData);
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
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    // Clean up current references before reconnecting
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _pingTimer?.cancel();

    // In production, add exponential backoff
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(currentUserId);
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
