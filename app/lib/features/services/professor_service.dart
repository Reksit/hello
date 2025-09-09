import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class ProfessorService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.professorsEndpoint}/profile/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get professor profile: $error');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.professorsEndpoint}/my-profile',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get my profile: $error');
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.professorsEndpoint}/my-profile',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  Future<Map<String, dynamic>> getTeachingStats([String? userId]) async {
    try {
      final endpoint = userId != null
          ? '${AppConstants.professorsEndpoint}/teaching-stats/$userId'
          : '${AppConstants.professorsEndpoint}/my-teaching-stats';
      
      final response = await _apiService.get(endpoint);
      return response.data;
    } catch (error) {
      throw Exception('Failed to get teaching stats: $error');
    }
  }

  Future<List<dynamic>> getMyStudents() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.professorsEndpoint}/my-students',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get students: $error');
    }
  }

  Future<List<dynamic>> getMyAssessments() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.professorsEndpoint}/my-assessments',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get assessments: $error');
    }
  }

  Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.professorsEndpoint}/assessments',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to create assessment: $error');
    }
  }

  Future<Map<String, dynamic>> updateAssessment(
    String assessmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.professorsEndpoint}/assessments/$assessmentId',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update assessment: $error');
    }
  }

  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _apiService.delete(
        '${AppConstants.professorsEndpoint}/assessments/$assessmentId',
      );
    } catch (error) {
      throw Exception('Failed to delete assessment: $error');
    }
  }

  Future<List<dynamic>> getAssessmentResults(String assessmentId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.professorsEndpoint}/assessments/$assessmentId/results',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get assessment results: $error');
    }
  }

  Future<Map<String, dynamic>> submitAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '/attendance/submit',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to submit attendance: $error');
    }
  }

  Future<List<dynamic>> getAttendanceRecords([String? className]) async {
    try {
      final queryParams = <String, dynamic>{};
      if (className != null) queryParams['className'] = className;
      
      final response = await _apiService.get(
        '/attendance/professor/records',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get attendance records: $error');
    }
  }

  Future<List<dynamic>> getStudentsForAttendance(
    String department,
    String className,
  ) async {
    try {
      final response = await _apiService.get(
        '/attendance/students',
        queryParameters: {
          'department': department,
          'className': className,
        },
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get students for attendance: $error');
    }
  }
}