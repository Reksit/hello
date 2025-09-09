import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class ConnectionService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> sendConnectionRequest(
    String recipientId,
    String message,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.connectionsEndpoint}/send-request',
        data: {
          'recipientId': recipientId,
          'message': message,
        },
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to send connection request: $error');
    }
  }

  Future<Map<String, dynamic>> acceptConnectionRequest(String connectionId) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.connectionsEndpoint}/$connectionId/accept',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to accept connection request: $error');
    }
  }

  Future<Map<String, dynamic>> rejectConnectionRequest(String connectionId) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.connectionsEndpoint}/$connectionId/reject',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to reject connection request: $error');
    }
  }

  Future<List<dynamic>> getPendingRequests() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.connectionsEndpoint}/pending',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get pending requests: $error');
    }
  }

  Future<List<dynamic>> getAcceptedConnections() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.connectionsEndpoint}/accepted',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get accepted connections: $error');
    }
  }

  Future<Map<String, dynamic>> getConnectionStatus(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.connectionsEndpoint}/status/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get connection status: $error');
    }
  }

  Future<Map<String, dynamic>> getConnectionCount() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.connectionsEndpoint}/count',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get connection count: $error');
    }
  }
}