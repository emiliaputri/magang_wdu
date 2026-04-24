import 'dart:convert';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    // Handle Laravel Database Notification format
    final data = map['data'] is Map ? map['data'] as Map<String, dynamic> : <String, dynamic>{};
    
    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: data['title'] ?? map['title'] ?? 'Notifikasi',
      message: data['message'] ?? map['message'] ?? '',
      timestamp: DateTime.parse(
        map['created_at'] ?? map['timestamp'] ?? DateTime.now().toIso8601String()
      ),
      isRead: map['read_at'] != null || (map['isRead'] ?? false),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotification.fromJson(String source) => AppNotification.fromMap(json.decode(source));
}
