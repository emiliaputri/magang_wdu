import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification_model.dart';
import '../service/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  final List<AppNotification> _notifications = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _loading = false;
  bool get loading => _loading;

  // Placeholder sound for "kring kring"
  static const String ringingSoundUrl = 'https://www.soundjay.com/phone/telephone-ring-03a.mp3';

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _service.fetchNotifications();
      _notifications.clear();
      _notifications.addAll(data.map((m) => AppNotification.fromMap(m)));
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addNotification({required String title, required String message}) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notification);
    _playRingingSound();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      final success = await _service.markAsRead(id);
      if (success) {
        _notifications[index].isRead = true;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    
    final success = await _service.markAllAsRead();
    if (success) {
      for (var n in _notifications) {
        n.isRead = true;
      }
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final success = await _service.deleteNotification(id);
    if (success) {
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    }
  }

  Future<void> clearNotifications() async {
    // If backend doesn't have clear all, we can loop delete or just clear local
    // For now, let's just clear local if backend doesn't support it, 
    // but the request mentioned markAllAsRead and individual delete.
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
    super.dispose();
  }
}
