import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class TaskService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getUserTasks() async {
    try {
      final response = await _apiService.get(AppConstants.tasksEndpoint);
      return response.data;
    } catch (error) {
      throw Exception('Failed to get user tasks: $error');
    }
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        AppConstants.tasksEndpoint,
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to create task: $error');
    }
  }

  Future<Map<String, dynamic>> generateRoadmap(String taskId) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.tasksEndpoint}/$taskId/roadmap',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to generate roadmap: $error');
    }
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    String taskId,
    String status,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.tasksEndpoint}/$taskId/status',
        data: {'status': status},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update task status: $error');
    }
  }
}