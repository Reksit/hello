import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class ManagementService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/stats',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get dashboard stats: $error');
    }
  }

  Future<Map<String, dynamic>> getStudentHeatmap(String studentId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/student/$studentId/heatmap',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get student heatmap: $error');
    }
  }

  Future<List<dynamic>> getAlumniApplications() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/alumni',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get alumni applications: $error');
    }
  }

  Future<String> approveAlumni(String alumniId, bool approved) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.managementEndpoint}/alumni/$alumniId/status',
        data: {'approved': approved},
      );
      return response.data.toString();
    } catch (error) {
      throw Exception('Failed to approve alumni: $error');
    }
  }

  Future<List<dynamic>> searchStudents(String email) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/students/search',
        queryParameters: {'email': email},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to search students: $error');
    }
  }

  Future<List<dynamic>> getApprovedAlumni() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/alumni-available',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get approved alumni: $error');
    }
  }

  Future<List<dynamic>> getAllAlumniEventRequests() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/alumni-event-requests',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get alumni event requests: $error');
    }
  }

  Future<Map<String, dynamic>> approveAlumniEventRequest(String requestId) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.managementEndpoint}/alumni-event-requests/$requestId/approve',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to approve alumni event request: $error');
    }
  }

  Future<Map<String, dynamic>> rejectAlumniEventRequest(
    String requestId,
    String? reason,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.managementEndpoint}/alumni-event-requests/$requestId/reject',
        data: {'reason': reason},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to reject alumni event request: $error');
    }
  }

  Future<Map<String, dynamic>> requestEventFromAlumni(
    String alumniId,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.managementEndpoint}/request-alumni-event/$alumniId',
        data: requestData,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to request event from alumni: $error');
    }
  }

  Future<List<dynamic>> getAllManagementEventRequests() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.managementEndpoint}/management-event-requests',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get management event requests: $error');
    }
  }

  Future<Map<String, dynamic>> analyzeStudentProfiles(String query) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.resumesEndpoint}/management/analyze-students',
        data: {'query': query},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to analyze student profiles: $error');
    }
  }
}