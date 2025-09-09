import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class EventsService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getApprovedEvents() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.eventsEndpoint}/approved',
      );
      return response.data;
    } catch (error) {
      // Fallback to debug endpoint
      try {
        final fallbackResponse = await _apiService.get('/debug/events');
        final data = fallbackResponse.data;
        return data['events'] ?? [];
      } catch (fallbackError) {
        throw Exception('Failed to get approved events: $error');
      }
    }
  }

  Future<Map<String, dynamic>> updateAttendance(
    String eventId,
    bool attending,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.eventsEndpoint}/$eventId/attendance',
        data: {'attending': attending},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update attendance: $error');
    }
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        AppConstants.eventsEndpoint,
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to create event: $error');
    }
  }

  Future<Map<String, dynamic>> updateEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.eventsEndpoint}/$eventId',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update event: $error');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _apiService.delete('${AppConstants.eventsEndpoint}/$eventId');
    } catch (error) {
      throw Exception('Failed to delete event: $error');
    }
  }
}