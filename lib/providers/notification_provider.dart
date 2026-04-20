import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Placeholder sound for "kring kring"
  static const String ringingSoundUrl = 'https://www.soundjay.com/phone/telephone-ring-03a.mp3';

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
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
    super.dispose();
  }
}
