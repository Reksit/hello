import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/signin',
        data: request.toJson(),
      );
      
      // Transform response to match our model
      final data = response.data;
      final user = UserModel(
        id: data['id'],
        email: data['email'],
        name: data['name'],
        role: data['role'],
        department: data['department'],
        className: data['className'],
        phoneNumber: data['phoneNumber'],
        verified: data['verified'] ?? false,
      );
      
      return AuthResponse(
        accessToken: data['accessToken'],
        user: user,
        refreshToken: data['refreshToken'],
      );
    } catch (error) {
      throw Exception('Login failed: ${error.toString()}');
    }
  }
  
  Future<String> register(RegisterRequest request) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/signup',
        data: request.toJson(),
      );
      
      return response.data.toString();
    } catch (error) {
      throw Exception('Registration failed: ${error.toString()}');
    }
  }
  
  Future<String> verifyOtp(String email, String otp) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );
      
      return response.data.toString();
    } catch (error) {
      throw Exception('OTP verification failed: ${error.toString()}');
    }
  }
  
  Future<String> resendOtp(String email) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.authEndpoint}/resend-otp',
        queryParameters: {'email': email},
      );
      
      return response.data.toString();
    } catch (error) {
      throw Exception('Failed to resend OTP: ${error.toString()}');
    }
  }
  
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
      throw Exception('Password change failed: ${error.toString()}');
    }
  }
}