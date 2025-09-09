import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class AttendanceService {
  final ApiService _apiService = ApiService();

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

  Future<List<dynamic>> getProfessorAttendanceRecords([String? className]) async {
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

  Future<Map<String, dynamic>> getStudentAttendanceSummary([String? studentId]) async {
    try {
      final endpoint = studentId != null
          ? '/attendance/student/$studentId/summary'
          : '/attendance/student/my-summary';
      
      final response = await _apiService.get(endpoint);
      return response.data;
    } catch (error) {
      throw Exception('Failed to get attendance summary: $error');
    }
  }

  Future<List<dynamic>> getStudentAttendanceDetails(
    String studentId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final response = await _apiService.get(
        '/attendance/student/$studentId/details',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get attendance details: $error');
    }
  }

  Future<Map<String, dynamic>> updateAttendanceRecord(
    String recordId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '/attendance/records/$recordId',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update attendance record: $error');
    }
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      await _apiService.delete('/attendance/records/$recordId');
    } catch (error) {
      throw Exception('Failed to delete attendance record: $error');
    }
  }

  Future<Map<String, dynamic>> getAttendanceStatistics(
    String className, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'className': className};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final response = await _apiService.get(
        '/attendance/statistics',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get attendance statistics: $error');
    }
  }
}