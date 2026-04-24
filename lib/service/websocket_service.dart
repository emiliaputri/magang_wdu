import 'package:flutter/foundation.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';
import '../core/constants/websocket_constants.dart';
import '../core/constants/endpoints.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  Echo? _echo;
  PusherClient? _pusherClient;

  Future<void> initEcho(String token) async {
    if (_echo != null) await disconnect();

    try {
      final authUrl = '${Endpoints.baseUrl}/broadcasting/auth';
      String host = WebSocketConstants.host;
      
      // Handle Chrome/Web and Emulator mapping
      if (host == 'localhost' || host == '127.0.0.1') {
        if (!kIsWeb) {
          final baseUrl = Endpoints.baseUrl;
          if (baseUrl.contains('10.0.2.2')) {
            host = '10.0.2.2';
          }
        }
      }

      debugPrint('[WebSocket] Connecting to $host:${WebSocketConstants.port}');

      PusherOptions options = PusherOptions(
        host: host,
        wsPort: WebSocketConstants.port,
        wssPort: WebSocketConstants.port,
        encrypted: false,
        cluster: 'mt1',
        auth: PusherAuth(
          authUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      _pusherClient = PusherClient(
        WebSocketConstants.key,
        options,
        autoConnect: false,
        enableLogging: true,
      );

      _echo = Echo(
        client: _pusherClient,
        broadcaster: EchoBroadcasterType.Pusher,
      );

      _pusherClient!.onConnectionStateChange((state) {
        debugPrint('[WebSocket] State: ${state?.currentState}');
      });

      _pusherClient!.onConnectionError((error) {
        debugPrint('[WebSocket] Error: ${error?.message}');
      });

      _pusherClient!.connect();
      debugPrint('[WebSocket] Connected initiated');
    } catch (e) {
      debugPrint('[WebSocket] Init Error: $e');
    }
  }

  Echo? get echo => _echo;

  Future<void> disconnect() async {
    _pusherClient?.disconnect();
    _echo = null;
    _pusherClient = null;
    debugPrint('[WebSocket] Disconnected');
  }
}
