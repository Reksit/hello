import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';

class PasswordService {
  final ApiService _apiService = ApiService();

  Future<String> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response.data.toString();
    } catch (error) {
      throw Exception('Failed to change password: $error');
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/reset-password',
        data: {'email': email},
      );
      return response.data.toString();
    } catch (error) {
      throw Exception('Failed to reset password: $error');
    }
  }

  Future<String> confirmPasswordReset(
    String email,
    String token,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/confirm-reset-password',
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
      return response.data.toString();
    } catch (error) {
      throw Exception('Failed to confirm password reset: $error');
    }
  }
}