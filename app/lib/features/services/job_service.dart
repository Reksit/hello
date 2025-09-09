import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class JobService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getAllJobs() async {
    try {
      final response = await _apiService.get(AppConstants.jobsEndpoint);
      return response.data;
    } catch (error) {
      throw Exception('Failed to get jobs: $error');
    }
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        AppConstants.jobsEndpoint,
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to create job: $error');
    }
  }

  Future<Map<String, dynamic>> updateJob(
    String jobId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.jobsEndpoint}/$jobId',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update job: $error');
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _apiService.delete('${AppConstants.jobsEndpoint}/$jobId');
    } catch (error) {
      throw Exception('Failed to delete job: $error');
    }
  }

  Future<Map<String, dynamic>> getJob(String jobId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.jobsEndpoint}/$jobId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get job: $error');
    }
  }

  Future<List<dynamic>> getMyJobs() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.jobsEndpoint}/my-jobs',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get my jobs: $error');
    }
  }

  Future<List<dynamic>> searchJobs(Map<String, dynamic> criteria) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.jobsEndpoint}/search',
        queryParameters: criteria,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to search jobs: $error');
    }
  }

  Future<Map<String, dynamic>> applyToJob(String jobId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.jobsEndpoint}/$jobId/apply',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to apply to job: $error');
    }
  }

  Future<List<dynamic>> getJobApplications(String jobId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.jobsEndpoint}/$jobId/applications',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get job applications: $error');
    }
  }
}