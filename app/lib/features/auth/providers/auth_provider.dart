import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/storage_service.dart';
import '../services/auth_service.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthState()) {
    _validateStoredAuth();
  }
  
  void _validateStoredAuth() {
    final storedToken = StorageService.getToken();
    final storedUserData = StorageService.getUser();
    
    if (storedToken != null && storedUserData != null) {
      try {
        // Validate token
        if (!JwtDecoder.isExpired(storedToken)) {
          final user = UserModel.fromJson(storedUserData);
          state = state.copyWith(
            user: user,
            token: storedToken,
          );
          print('Valid token found, user authenticated: ${user.name}');
        } else {
          print('Token expired, clearing storage');
          _clearAuth();
        }
      } catch (error) {
        print('Error validating stored auth: $error');
        _clearAuth();
      }
    }
  }
  
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.login(
        LoginRequest(email: email, password: password),
      );
      
      // Save to storage
      await StorageService.saveToken(response.accessToken);
      await StorageService.saveUser(response.user.toJson());
      
      state = state.copyWith(
        user: response.user,
        token: response.accessToken,
        isLoading: false,
      );
      
      print('Login successful: ${response.user.name} (${response.user.role})');
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.register(request);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.verifyOtp(email, otp);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> resendOtp(String email) async {
    try {
      await _authService.resendOtp(email);
    } catch (error) {
      rethrow;
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      rethrow;
    }
  }
  
  void logout() {
    _clearAuth();
    print('User logged out');
  }
  
  void _clearAuth() {
    StorageService.removeToken();
    StorageService.removeUser();
    
    // Clear other app-specific storage
    final keys = StorageService.getKeys();
    for (final key in keys) {
      if (key.startsWith('app_') || key.startsWith('assessment_')) {
        StorageService.remove(key);
      }
    }
    
    state = const AuthState();
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});