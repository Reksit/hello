import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class ActivityService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> logActivity(String type, String description) async {
    try {
      final response = await _apiService.post(
        AppConstants.activitiesEndpoint,
        data: {
          'type': type,
          'description': description,
        },
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to log activity: $error');
    }
  }

  Future<List<dynamic>> getUserActivities(
    String userId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final response = await _apiService.get(
        '${AppConstants.activitiesEndpoint}/user/$userId',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get user activities: $error');
    }
  }

  Future<Map<String, dynamic>> getHeatmapData(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.activitiesEndpoint}/heatmap/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get heatmap data: $error');
    }
  }
}