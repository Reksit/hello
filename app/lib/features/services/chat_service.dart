import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> sendAIMessage(String message) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.chatEndpoint}/ai',
        data: {'message': message},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to send AI message: $error');
    }
  }

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.chatEndpoint}/conversations',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get conversations: $error');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.chatEndpoint}/users',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get all users: $error');
    }
  }

  Future<void> markMessagesAsRead(String userId) async {
    try {
      await _apiService.put(
        '${AppConstants.chatEndpoint}/mark-read/$userId',
      );
    } catch (error) {
      throw Exception('Failed to mark messages as read: $error');
    }
  }

  Future<List<dynamic>> getChatHistory(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.chatEndpoint}/history/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get chat history: $error');
    }
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.chatEndpoint}/send',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to send message: $error');
    }
  }

  Future<List<dynamic>> getAlumniDirectory() async {
    try {
      final response = await _apiService.get('/users/alumni-directory');
      return response.data;
    } catch (error) {
      throw Exception('Failed to get alumni directory: $error');
    }
  }
}