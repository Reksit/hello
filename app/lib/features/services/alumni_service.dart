import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class AlumniService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.alumniEndpoint}/profile/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get alumni profile: $error');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.alumniEndpoint}/my-profile',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get my profile: $error');
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.alumniEndpoint}/my-profile',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  Future<Map<String, dynamic>> submitEventRequest(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '/api/alumni-events/request',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to submit event request: $error');
    }
  }

  Future<List<dynamic>> getApprovedEvents() async {
    try {
      final response = await _apiService.get('/api/alumni-events/approved');
      return response.data;
    } catch (error) {
      throw Exception('Failed to get approved events: $error');
    }
  }

  Future<List<dynamic>> getPendingManagementRequests() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.alumniEndpoint}/pending-requests',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get pending management requests: $error');
    }
  }

  Future<Map<String, dynamic>> acceptManagementEventRequest(
    String requestId,
    String responseMessage,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.alumniEndpoint}/accept-management-request/$requestId',
        data: {'response': responseMessage},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to accept management event request: $error');
    }
  }

  Future<Map<String, dynamic>> rejectManagementEventRequest(
    String requestId,
    String reason,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.alumniEndpoint}/reject-management-request/$requestId',
        data: {'reason': reason},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to reject management event request: $error');
    }
  }

  Future<Map<String, dynamic>> getAlumniStats() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.alumniEndpoint}/stats',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get alumni stats: $error');
    }
  }

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

  Future<List<dynamic>> getAllVerifiedAlumni() async {
    try {
      final response = await _apiService.get('/api/alumni-directory');
      return response.data;
    } catch (error) {
      throw Exception('Failed to get verified alumni: $error');
    }
  }

  Future<List<dynamic>> getAllVerifiedAlumniForAlumni() async {
    try {
      final response = await _apiService.get('/api/alumni-directory/for-alumni');
      return response.data;
    } catch (error) {
      throw Exception('Failed to get verified alumni for alumni: $error');
    }
  }
}