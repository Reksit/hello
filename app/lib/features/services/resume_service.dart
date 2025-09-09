import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class ResumeService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> uploadResume(File file) async {
    try {
      final response = await _apiService.uploadFile(
        '${AppConstants.resumesEndpoint}/upload',
        file,
        fieldName: 'file',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to upload resume: $error');
    }
  }

  Future<List<dynamic>> getMyResumes() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/my',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get resumes: $error');
    }
  }

  Future<Map<String, dynamic>> getCurrentResume() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/current',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get current resume: $error');
    }
  }

  Future<Map<String, dynamic>> getResume(String id) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/$id',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get resume: $error');
    }
  }

  Future<void> downloadResume(String id, String savePath) async {
    try {
      await _apiService.downloadFile(
        '${AppConstants.resumesEndpoint}/$id/download',
        savePath,
      );
    } catch (error) {
      throw Exception('Failed to download resume: $error');
    }
  }

  Future<Map<String, dynamic>> activateResume(String id) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.resumesEndpoint}/$id/activate',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to activate resume: $error');
    }
  }

  Future<void> deleteResume(String id) async {
    try {
      await _apiService.delete(
        '${AppConstants.resumesEndpoint}/$id',
      );
    } catch (error) {
      throw Exception('Failed to delete resume: $error');
    }
  }

  Future<Map<String, dynamic>> updateResume(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.resumesEndpoint}/$id',
        data: data,
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to update resume: $error');
    }
  }

  Future<Map<String, dynamic>> renameResume(String id, String newName) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.resumesEndpoint}/$id/rename',
        data: {'fileName': newName},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to rename resume: $error');
    }
  }

  Future<Map<String, dynamic>> analyzeResumeATS(String id) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.resumesEndpoint}/$id/analyze-ats',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to analyze resume: $error');
    }
  }

  Future<Map<String, dynamic>> sendATSToManagement(String id) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.resumesEndpoint}/$id/send-ats-to-management',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to send ATS to management: $error');
    }
  }

  Future<List<dynamic>> searchBySkill(String skill) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/search',
        queryParameters: {'skill': skill},
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to search resumes: $error');
    }
  }

  Future<Map<String, dynamic>> getUserResume(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/user/$userId',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get user resume: $error');
    }
  }

  Future<List<dynamic>> getAllStudentResumes() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/management/all',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get all student resumes: $error');
    }
  }

  Future<List<dynamic>> getResumesWithATS() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.resumesEndpoint}/management/with-ats',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to get resumes with ATS: $error');
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

  Future<Map<String, dynamic>> markResumeAsSent(String id) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.resumesEndpoint}/management/$id/mark-sent',
      );
      return response.data;
    } catch (error) {
      throw Exception('Failed to mark resume as sent: $error');
    }
  }
}