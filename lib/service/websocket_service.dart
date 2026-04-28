import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../core/constants/websocket_constants.dart';
import '../core/constants/endpoints.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final PusherChannelsFlutter _pusher =
  PusherChannelsFlutter.getInstance();

  bool _isConnected = false;

  Future<void> initEcho(String token) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      final authUrl = '${Endpoints.baseUrl}/broadcasting/auth';
      String host = WebSocketConstants.host;

      // Handle emulator mapping
      if (host == 'localhost' || host == '127.0.0.1') {
        if (!kIsWeb) {
          final baseUrl = Endpoints.baseUrl;
          if (baseUrl.contains('10.0.2.2')) {
            host = '10.0.2.2';
          }
        }
      }

      debugPrint('[WebSocket] Connecting to $host:${WebSocketConstants.port}');

      await _pusher.init(
        apiKey: WebSocketConstants.key,
        cluster: 'mt1',

        // Auth Laravel (Bearer Token)
        authEndpoint: authUrl,
        authParams: {
          'headers': {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          }
        },

        // ✅ FIX di sini (tidak pakai state?.currentState lagi)
        onConnectionStateChange: (currentState, previousState) {
          debugPrint('[WebSocket] State: $currentState');
        },

        // ✅ FIX di sini (tidak pakai error?.message)
        onError: (message, code, exception) {
          debugPrint('[WebSocket] Error: $message');
        },

        onEvent: (event) {
          debugPrint('[WebSocket] Event: ${event.data}');
        },
      );

      await _pusher.connect();
      _isConnected = true;

      debugPrint('[WebSocket] Connected');
    } catch (e) {
      debugPrint('[WebSocket] Init Error: $e');
    }
  }

  /// Subscribe ke channel (contoh: private-chat.1)
  Future<void> subscribe(String channelName) async {
    try {
      await _pusher.subscribe(channelName: channelName);
      debugPrint('[WebSocket] Subscribed: $channelName');
    } catch (e) {
      debugPrint('[WebSocket] Subscribe Error: $e');
    }
  }

  /// Unsubscribe channel
  Future<void> unsubscribe(String channelName) async {
    try {
      await _pusher.unsubscribe(channelName: channelName);
      debugPrint('[WebSocket] Unsubscribed: $channelName');
    } catch (e) {
      debugPrint('[WebSocket] Unsubscribe Error: $e');
    }
  }

  Future<void> disconnect() async {
    await _pusher.disconnect();
    _isConnected = false;
    debugPrint('[WebSocket] Disconnected');
  }
}