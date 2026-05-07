import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';

class NotificationService {
  final _api = ApiClient();

  /// Mengambil daftar notifikasi
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await _api.get(Endpoints.notifications);
    if (response.success && response.data != null) {
      // Laravel notification data is usually in 'data' or a list directly
      final data = response.data!['notifications'] ?? response.data!['data'] ?? [];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return [];
  }

  /// Menandai satu notifikasi sebagai dibaca
  Future<bool> markAsRead(String id) async {
    final response = await _api.post(
      Endpoints.markNotificationAsRead(id),
      body: {},
    );
    return response.success;
  }

  /// Menandai semua notifikasi sebagai dibaca
  Future<bool> markAllAsRead() async {
    final response = await _api.post(
      Endpoints.markAllNotificationsAsRead,
      body: {},
    );
    return response.success;
  }

  /// Menghapus satu notifikasi
  Future<bool> deleteNotification(String id) async {
    final response = await _api.delete(
      Endpoints.deleteNotification(id),
    );
    return response.success;
  }
}
