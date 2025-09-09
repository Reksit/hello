import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    required String role,
    String? department,
    String? className,
    String? phoneNumber,
    @Default(false) bool verified,
    String? profilePicture,
    String? bio,
    @Default([]) List<String> skills,
    String? location,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    
    // Student specific
    String? studentId,
    String? course,
    String? year,
    double? cgpa,
    String? semester,
    
    // Professor specific
    String? employeeId,
    String? designation,
    int? experience,
    @Default([]) List<String> subjectsTeaching,
    @Default([]) List<String> researchInterests,
    int? publications,
    int? studentsSupervised,
    
    // Alumni specific
    int? graduationYear,
    String? batch,
    String? currentCompany,
    String? currentPosition,
    int? workExperience,
    @Default([]) List<String> achievements,
    @Default(false) bool mentorshipAvailable,
    String? placedCompany,
    
    // Timestamps
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required UserModel user,
    String? refreshToken,
    DateTime? expiresAt,
  }) = _AuthResponse;
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;
  
  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String name,
    required String email,
    String? password,
    required String phoneNumber,
    required String department,
    String? className,
    required String role,
    String? graduationYear,
    String? batch,
    String? placedCompany,
  }) = _RegisterRequest;
  
  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
}