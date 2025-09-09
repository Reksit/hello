import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class StudentService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.studentsEndpoint}/profile/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get student profile: $error');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.studentsEndpoint}/my-profile',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get my profile: $error');
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.studentsEndpoint}/my-profile',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  Future<List<dynamic>> getAssessmentHistory([String? userId]) async {
    try {
      final endpoint = userId != null
          ? '${AppConstants.studentsEndpoint}/assessment-history/$userId'
          : '${AppConstants.studentsEndpoint}/my-assessment-history';
      
      final response = await _apiService.get(endpoint);
      return response.data;
    } catch (error) {
      throw Exception('Failed to get assessment history: $error');
    }
  }
}