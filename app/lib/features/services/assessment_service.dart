import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class AssessmentService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> generateAIAssessment(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.assessmentsEndpoint}/generate-ai',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to generate AI assessment: $error');
    }
  }

  Future<List<dynamic>> getStudentAssessments() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.assessmentsEndpoint}/student',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get student assessments: $error');
    }
  }

  Future<Map<String, dynamic>> submitAssessment(
    String assessmentId,
    Map<String, dynamic> submission,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.assessmentsEndpoint}/$assessmentId/submit',
        data: submission,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to submit assessment: $error');
    }
  }

  Future<List<dynamic>> getAssessmentResults(String assessmentId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.assessmentsEndpoint}/$assessmentId/results',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get assessment results: $error');
    }
  }

  Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        AppConstants.assessmentsEndpoint,
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to create assessment: $error');
    }
  }

  Future<List<dynamic>> getProfessorAssessments() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.assessmentsEndpoint}/professor',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get professor assessments: $error');
    }
  }

  Future<List<dynamic>> searchStudents(String query) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.assessmentsEndpoint}/search-students',
        queryParameters: {'query': query},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to search students: $error');
    }
  }

  Future<Map<String, dynamic>> updateAssessment(
    String assessmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.assessmentsEndpoint}/$assessmentId',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update assessment: $error');
    }
  }
}