// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      department: json['department'] as String?,
      className: json['className'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      verified: json['verified'] as bool? ?? false,
      profilePicture: json['profilePicture'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      location: json['location'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      studentId: json['studentId'] as String?,
      course: json['course'] as String?,
      year: json['year'] as String?,
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      semester: json['semester'] as String?,
      employeeId: json['employeeId'] as String?,
      designation: json['designation'] as String?,
      experience: json['experience'] as int?,
      subjectsTeaching: (json['subjectsTeaching'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      researchInterests: (json['researchInterests'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      publications: json['publications'] as int?,
      studentsSupervised: json['studentsSupervised'] as int?,
      graduationYear: json['graduationYear'] as int?,
      batch: json['batch'] as String?,
      currentCompany: json['currentCompany'] as String?,
      currentPosition: json['currentPosition'] as String?,
      workExperience: json['workExperience'] as int?,
      achievements: (json['achievements'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      mentorshipAvailable: json['mentorshipAvailable'] as bool? ?? false,
      placedCompany: json['placedCompany'] as String?,
      createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
      lastActive: json['lastActive'] == null ? null : DateTime.parse(json['lastActive'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'role': instance.role,
      'department': instance.department,
      'className': instance.className,
      'phoneNumber': instance.phoneNumber,
      'verified': instance.verified,
      'profilePicture': instance.profilePicture,
      'bio': instance.bio,
      'skills': instance.skills,
      'location': instance.location,
      'linkedinUrl': instance.linkedinUrl,
      'githubUrl': instance.githubUrl,
      'portfolioUrl': instance.portfolioUrl,
      'studentId': instance.studentId,
      'course': instance.course,
      'year': instance.year,
      'cgpa': instance.cgpa,
      'semester': instance.semester,
      'employeeId': instance.employeeId,
      'designation': instance.designation,
      'experience': instance.experience,
      'subjectsTeaching': instance.subjectsTeaching,
      'researchInterests': instance.researchInterests,
      'publications': instance.publications,
      'studentsSupervised': instance.studentsSupervised,
      'graduationYear': instance.graduationYear,
      'batch': instance.batch,
      'currentCompany': instance.currentCompany,
      'currentPosition': instance.currentPosition,
      'workExperience': instance.workExperience,
      'achievements': instance.achievements,
      'mentorshipAvailable': instance.mentorshipAvailable,
      'placedCompany': instance.placedCompany,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastActive': instance.lastActive?.toIso8601String(),
    };

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      accessToken: json['accessToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'user': instance.user,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map<String, dynamic> json) =>
    _$LoginRequestImpl(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

_$RegisterRequestImpl _$$RegisterRequestImplFromJson(Map<String, dynamic> json) =>
    _$RegisterRequestImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String?,
      phoneNumber: json['phoneNumber'] as String,
      department: json['department'] as String,
      className: json['className'] as String?,
      role: json['role'] as String,
      graduationYear: json['graduationYear'] as String?,
      batch: json['batch'] as String?,
      placedCompany: json['placedCompany'] as String?,
    );

Map<String, dynamic> _$$RegisterRequestImplToJson(_$RegisterRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
      'phoneNumber': instance.phoneNumber,
      'department': instance.department,
      'className': instance.className,
      'role': instance.role,
      'graduationYear': instance.graduationYear,
      'batch': instance.batch,
      'placedCompany': instance.placedCompany,
    };