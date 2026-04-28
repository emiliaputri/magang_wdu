import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../models/notification_model.dart';
import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../service/websocket_service.dart';
import '../core/utils/storage.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiClient _api = ApiClient();
  final WebSocketService _ws = WebSocketService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static const String ringingSoundUrl =
      'https://www.soundjay.com/phone/telephone-ring-03a.mp3';

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    init();
  }

  Future<void> init() async {
    final hasToken = await StorageHelper.hasToken();
    if (hasToken) {
      debugPrint('[NotificationProvider] User token found, initializing...');
      await fetchNotifications();
      await setupWebSocket();
    } else {
      debugPrint('[NotificationProvider] No user token found');
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(Endpoints.notifications);
      if (response.success) {
        final List<dynamic> data =
            response.data?['notifications'] ?? [];
        _notifications.clear();
        for (var item in data) {
          _notifications.add(AppNotification.fromMap(item));
        }
        debugPrint(
            '[NotificationProvider] Fetched ${_notifications.length} notifications');
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setupWebSocket() async {
    final token = await StorageHelper.getToken();
    final userId = await StorageHelper.getUserId();

    if (token != null && userId != null) {
      debugPrint(
          '[NotificationProvider] Setting up WS for User ID: $userId');

      await _ws.initEcho(token);

      final channelName = 'private-App.Models.User.$userId';

      // ✅ subscribe channel
      await _ws.subscribe(channelName);

      // ✅ listen event (pengganti Echo)
      PusherChannelsFlutter.getInstance().onEvent = (event) {
        if (event.channelName == channelName) {
          debugPrint(
              '[NotificationProvider] Event: ${event.eventName}');
          debugPrint(
              '[NotificationProvider] Data: ${event.data}');

          // 🎯 khusus Laravel Notification
          if (event.eventName ==
              'Illuminate\\Notifications\\Events\\BroadcastNotificationCreated') {
            _handleIncomingNotification(event.data);
          }

          // 🔁 fallback kalau nama event beda
          else {
            _handleIncomingNotification(event.data);
          }
        }
      };
    }
  }

  void _handleIncomingNotification(dynamic data) {
    final id = data['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    if (_notifications.any((n) => n.id == id)) return;

    String title =
        data['title'] ?? data['data']?['title'] ?? 'Notifikasi Baru';
    String message =
        data['message'] ?? data['data']?['message'] ??
            'Ada pembaruan status survey.';

    final notification = AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications.insert(0, notification);
    _playRingingSound();
    notifyListeners();
  }

  void addNotification({
    required String title,
    required String message,
    bool playRinging = false,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);

    if (playRinging) {
      _playRingingSound();
    }

    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      if (_notifications[index].isRead) return;

      _notifications[index].isRead = true;
      notifyListeners();

      try {
        await _api.post(Endpoints.markNotificationRead(id), body: {});
      } catch (e) {
        debugPrint(
            '[NotificationProvider] Mark as read error: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    final unreadItems =
    _notifications.where((n) => !n.isRead).toList();
    if (unreadItems.isEmpty) return;

    for (var n in _notifications) {
      n.isRead = true;
    }

    notifyListeners();

    try {
      await _api.post(Endpoints.markAllNotificationsRead,
          body: {});
    } catch (e) {
      debugPrint(
          '[NotificationProvider] Mark all as read error: $e');
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  Future<void> _playRingingSound() async {
    try {
      await _audioPlayer.play(UrlSource(ringingSoundUrl));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _ws.disconnect();
    super.dispose();
  }
}