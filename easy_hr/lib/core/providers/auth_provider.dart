import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// ============================================
// User Model
// ============================================
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final String companyId;
  final String companyName;
  final String? profilePhotoUrl;
  final String language;
  final bool darkMode;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.companyId,
    required this.companyName,
    this.profilePhotoUrl,
    this.language = 'mm',
    this.darkMode = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'employee',
      companyId: json['company_id'] ?? '',
      companyName: json['company_name'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      language: json['language'] ?? 'mm',
      darkMode: json['dark_mode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone,
    'role': role, 'company_id': companyId, 'company_name': companyName,
    'profile_photo_url': profilePhotoUrl, 'language': language, 'dark_mode': darkMode,
  };

  bool get isOwner => role == 'owner';
  bool get isHR => role == 'hr_manager';
  bool get isAdmin => role == 'owner' || role == 'hr_manager';
  bool get isDepartmentHead => role == 'department_head';
}

// ============================================
// Auth State
// ============================================
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({this.user, this.isLoading = false, this.error, this.isAuthenticated = false});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? isAuthenticated}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ============================================
// Auth Notifier
// ============================================
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(AuthState()) {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    final token = await _api.getToken();

    if (userJson != null && token != null) {
      final user = UserModel.fromJson(jsonDecode(userJson));
      state = state.copyWith(user: user, isAuthenticated: true);
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // Admin Login (Email + Password)
  Future<bool> adminLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.adminLogin(email, password);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      await _saveUser(user);
      state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // Employee OTP Login
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.requestOtp(phone);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      rethrow;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.verifyOtp(phone, otp);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      await _saveUser(user);
      state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // Firebase Phone Auth Login
  Future<bool> firebasePhoneLogin(String firebaseIdToken, String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.firebasePhoneLogin(firebaseIdToken, phone);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      await _saveUser(user);
      state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    state = AuthState();
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      return error.response?.data?['message'] ?? 'Connection error';
    }
    return error.toString();
  }
}

// ============================================
// Providers
// ============================================
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

final darkModeProvider = StateProvider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.user?.darkMode ?? false;
});

final languageProvider = StateProvider<String>((ref) {
  final auth = ref.watch(authProvider);
  return auth.user?.language ?? 'mm';
});