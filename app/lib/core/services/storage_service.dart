import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }
  
  // Token management
  static Future<void> saveToken(String token) async {
    await prefs.setString(AppConstants.tokenKey, token);
  }
  
  static String? getToken() {
    return prefs.getString(AppConstants.tokenKey);
  }
  
  static Future<void> removeToken() async {
    await prefs.remove(AppConstants.tokenKey);
  }
  
  // User data management
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await prefs.setString(AppConstants.userKey, jsonEncode(user));
  }
  
  static Map<String, dynamic>? getUser() {
    final userString = prefs.getString(AppConstants.userKey);
    if (userString != null) {
      return jsonDecode(userString) as Map<String, dynamic>;
    }
    return null;
  }
  
  static Future<void> removeUser() async {
    await prefs.remove(AppConstants.userKey);
  }
  
  // Submitted assessments tracking
  static Future<void> saveSubmittedAssessment(String assessmentId) async {
    final submitted = getSubmittedAssessments();
    submitted.add(assessmentId);
    await prefs.setStringList(AppConstants.submittedAssessmentsKey, submitted.toList());
  }
  
  static Set<String> getSubmittedAssessments() {
    final submitted = prefs.getStringList(AppConstants.submittedAssessmentsKey) ?? [];
    return submitted.toSet();
  }
  
  static Future<void> removeSubmittedAssessment(String assessmentId) async {
    final submitted = getSubmittedAssessments();
    submitted.remove(assessmentId);
    await prefs.setStringList(AppConstants.submittedAssessmentsKey, submitted.toList());
  }
  
  // Generic storage methods
  static Future<void> saveString(String key, String value) async {
    await prefs.setString(key, value);
  }
  
  static String? getString(String key) {
    return prefs.getString(key);
  }
  
  static Future<void> saveBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return prefs.getBool(key);
  }
  
  static Future<void> saveInt(String key, int value) async {
    await prefs.setInt(key, value);
  }
  
  static int? getInt(String key) {
    return prefs.getInt(key);
  }
  
  static Future<void> saveDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }
  
  static double? getDouble(String key) {
    return prefs.getDouble(key);
  }
  
  static Future<void> saveStringList(String key, List<String> value) async {
    await prefs.setStringList(key, value);
  }
  
  static List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }
  
  static Future<void> remove(String key) async {
    await prefs.remove(key);
  }
  
  static Future<void> clear() async {
    await prefs.clear();
  }
  
  // Check if key exists
  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }
  
  // Get all keys
  static Set<String> getKeys() {
    return prefs.getKeys();
  }
}