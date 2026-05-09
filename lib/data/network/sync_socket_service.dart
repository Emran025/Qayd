import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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

  // Exponential backoff state
  int _reconnectAttempts = 0;
  static const int _maxBackoffSeconds = 60;

  // Lifecycle state: prevents reconnect after explicit disconnect()
  bool _intentionallyStopped = false;

  // Reusable Dio instance — not re-created per message
  late final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Broadcast streams — created once and reused (not re-created on reconnect)
  final _nodeStreamController = StreamController<SyncNode>.broadcast();
  final _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _streamsOpen = true;

  /// Stream of instantly pushed encrypted event nodes from counterparts
  Stream<SyncNode> get incomingNodes => _nodeStreamController.stream;

  /// Stream of all raw socket events for external listening (e.g. EmailVerified)
  Stream<Map<String, dynamic>> get socketEvents =>
      _eventStreamController.stream;

  /// Connects to the Laravel WebSocket socket (Using Reverb/Custom port).
  Future<void> connect(int currentUserId) async {
    _intentionallyStopped = false;
    _dropCurrentConnection();

    final token = await tokenProvider();
    if (token == null) return;

    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      await _channel?.ready;

      // Reset backoff on successful connection
      _reconnectAttempts = 0;

      _subscription = _channel?.stream.listen(
        (message) async {
          try {
            final payload = jsonDecode(message as String);
            final eventName = payload['event'] as String?;

            // 1. Handle Pusher Connection Established Handshake
            if (eventName == 'pusher:connection_established') {
              final dataString = payload['data'];
              final dataObj = jsonDecode(dataString as String);
              final socketId = dataObj['socket_id'];

              final channelName = 'private-user.sync.$currentUserId';
              debugPrint(
                  'WS: Authenticating channel $channelName for socket $socketId');

              try {
                final response = await _dio.post(
                  authUrl,
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
                    },
                  ),
                );

                final authHash = response.data['auth'];
                debugPrint('WS: Auth success for $channelName');

                _channel?.sink.add(jsonEncode({
                  'event': 'pusher:subscribe',
                  'data': {'auth': authHash, 'channel': channelName},
                }));

                // Keep-alive ping every 30s
                _pingTimer?.cancel();
                _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
                  _channel?.sink
                      .add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
                });
              } catch (e) {
                debugPrint('WS: Auth failed: $e');
              }
            }

            final data = payload['data'];
            final dataMap = data is String
                ? (jsonDecode(data) as Map<String, dynamic>?)
                : (data as Map<String, dynamic>?);

            if (dataMap != null && _streamsOpen) {
              _eventStreamController.add({
                'event': eventName,
                'data': dataMap,
                'channel': payload['channel'],
              });

              if (eventName == 'sync.node.dispatched' ||
                  eventName == 'App\\Events\\SyncNodeDispatched') {
                final nodeData = dataMap['node'] ?? dataMap;
                final node =
                    SyncNode.fromJson(nodeData as Map<String, dynamic>);
                _nodeStreamController.add(node);
              }
            }
          } catch (e) {
            debugPrint('WS: Parse error: $e');
          }
        },
        onError: (e) {
          debugPrint('WS: Stream error: $e');
          _scheduleReconnect(currentUserId);
        },
        onDone: () {
          debugPrint('WS: Connection closed. Reconnecting...');
          _scheduleReconnect(currentUserId);
        },
      );
    } catch (e) {
      debugPrint('WS: Connect error: $e');
      _scheduleReconnect(currentUserId);
    }
  }

  /// Drops the current WS connection without scheduling a reconnect.
  void _dropCurrentConnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Schedules a reconnect with exponential backoff (5s → 10s → 20s → ... → 60s max).
  void _scheduleReconnect(int currentUserId) {
    if (_intentionallyStopped) return;
    if (_reconnectTimer?.isActive ?? false) return;

    final delay = Duration(
      seconds: (_reconnectAttempts == 0
              ? 5
              : (5 * (1 << _reconnectAttempts)).clamp(5, _maxBackoffSeconds))
          .toInt(),
    );
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(0, 6);

    debugPrint('WS: Reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () => connect(currentUserId));
  }

  /// Cleanly stops the WebSocket and cancels all timers.
  /// Closes the broadcast streams — call this only when the service is
  /// being permanently disposed (e.g. user logout).
  void disconnect({bool closeStreams = false}) {
    _intentionallyStopped = true;
    _dropCurrentConnection();

    if (closeStreams && _streamsOpen) {
      _streamsOpen = false;
      _nodeStreamController.close();
      _eventStreamController.close();
    }
  }
}
