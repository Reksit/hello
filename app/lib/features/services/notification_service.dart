import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _apiService.get(AppConstants.notificationsEndpoint);
      return response.data;
    } catch (error) {
      throw Exception('Failed to get notifications: $error');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.notificationsEndpoint}/count',
      );
      return response.data ?? 0;
    } catch (error) {
      throw Exception('Failed to get unread count: $error');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.put(
        '${AppConstants.notificationsEndpoint}/$notificationId/read',
      );
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.put(
        '${AppConstants.notificationsEndpoint}/mark-all-read',
      );
    } catch (error) {
      throw Exception('Failed to mark all notifications as read: $error');
    }
  }

  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        AppConstants.notificationsEndpoint,
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to create notification: $error');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiService.delete(
        '${AppConstants.notificationsEndpoint}/$notificationId',
      );
    } catch (error) {
      throw Exception('Failed to delete notification: $error');
    }
  }
}