import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:crypto/crypto.dart';
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
// Subscription Model
// ============================================
class SubscriptionModel {
  final String plan;
  final String status;
  final String? expires;
  final int daysRemaining;
  final int maxEmployees;
  final bool isExpired;

  SubscriptionModel({
    this.plan = 'free',
    this.status = 'active',
    this.expires,
    this.daysRemaining = 0,
    this.maxEmployees = 9,
    this.isExpired = false,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      expires: json['expires'],
      daysRemaining: json['days_remaining'] ?? 0,
      maxEmployees: json['max_employees'] ?? 9,
      isExpired: json['is_expired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'plan': plan, 'status': status, 'expires': expires,
    'days_remaining': daysRemaining, 'max_employees': maxEmployees,
    'is_expired': isExpired,
  };

  bool get isFree => plan == 'free';
  bool get isPaid => !isFree;
  bool get isTrialExpiringSoon => daysRemaining > 0 && daysRemaining <= 7;
}

// ============================================
// Auth State
// ============================================
class AuthState {
  final UserModel? user;
  final SubscriptionModel? subscription;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({this.user, this.subscription, this.isLoading = false, this.error, this.isAuthenticated = false});

  AuthState copyWith({UserModel? user, SubscriptionModel? subscription, bool? isLoading, String? error, bool? isAuthenticated}) {
    return AuthState(
      user: user ?? this.user,
      subscription: subscription ?? this.subscription,
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
    final subJson = prefs.getString('subscription_data');
    final token = await _api.getToken();

    if (userJson != null && token != null) {
      final user = UserModel.fromJson(jsonDecode(userJson));
      final sub = subJson != null
          ? SubscriptionModel.fromJson(jsonDecode(subJson))
          : SubscriptionModel();
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true);
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<void> _saveSubscription(SubscriptionModel sub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_data', jsonEncode(sub.toJson()));
  }

  // Admin Login (Email + Password)
  Future<bool> adminLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.adminLogin(email, password);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
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
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // PIN + Device Binding Login
  Future<bool> pinLogin(String phone, String pin, String deviceId, String? deviceName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.pinLogin(phone, pin, deviceId, deviceName);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
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
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>?> googleSignIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final gsi = GoogleSignIn(scopes: ['email']);
      // Disconnect + sign out to force account picker every time
      try { await gsi.disconnect(); } catch (_) {}
      try { await gsi.signOut(); } catch (_) {}
      await fb.FirebaseAuth.instance.signOut();
      final googleUser = await gsi.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return null; // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');

      final response = await _api.googleLogin(idToken);

      if (response['needs_onboarding'] == true) {
        state = state.copyWith(isLoading: false);
        return response; // Return to UI for onboarding
      }

      // Existing user — login success
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return null;
    }
  }

  // Apple Sign-In
  Future<Map<String, dynamic>?> appleSignIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');

      // Apple may only provide name on first sign-in
      final displayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      final response = await _api.appleLogin(idToken);

      if (response['needs_onboarding'] == true) {
        state = state.copyWith(isLoading: false);
        // Pass Apple user info for onboarding
        response['apple_user'] = {
          'email': appleCredential.email ?? userCredential.user?.email ?? '',
          'name': displayName.isNotEmpty ? displayName : (userCredential.user?.displayName ?? ''),
        };
        return response;
      }

      // Existing user — login success
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Accept Employee Invitation
  Future<bool> acceptInvite(String inviteCode, String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.acceptInvite(inviteCode, phone);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // Onboard Company (after Google login, new user)
  Future<bool> onboardCompany(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.onboardCompany(data);
      await _api.saveToken(response['access_token']);
      final user = UserModel.fromJson(response['user']);
      final sub = response['subscription'] != null
          ? SubscriptionModel.fromJson(response['subscription'])
          : SubscriptionModel();
      await _saveUser(user);
      await _saveSubscription(sub);
      state = state.copyWith(user: user, subscription: sub, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  // Update Profile Photo
  void updateProfilePhoto(String url) {
    if (state.user != null) {
      final updatedUser = UserModel(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        phone: state.user!.phone,
        role: state.user!.role,
        companyId: state.user!.companyId,
        companyName: state.user!.companyName,
        profilePhotoUrl: url,
        language: state.user!.language,
        darkMode: state.user!.darkMode,
      );
      _saveUser(updatedUser);
      state = state.copyWith(user: updatedUser);
    }
  }

  // Logout
  Future<void> logout() async {
    await _api.clearToken();
    // Clear Google + Firebase sessions so next login shows account picker
    try { await GoogleSignIn().disconnect(); } catch (_) {}
    try { await GoogleSignIn().signOut(); } catch (_) {}
    try { await fb.FirebaseAuth.instance.signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('subscription_data');
    state = AuthState();
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      final serverMsg = error.response?.data?['message'];
      if (serverMsg != null) return serverMsg.toString();

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request timeout. Please try again.';
      }

      final underlying = error.error;
      if (underlying is SocketException) {
        return 'No internet connection';
      }
      if (underlying is HandshakeException) {
        return 'SSL connection failed';
      }

      return 'Connection error';
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

// Persisted dark mode provider — saves to SharedPreferences
class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? false;
  }
  void toggle() => set(!state);
  void set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }
}

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

// Persisted language provider — saves to SharedPreferences
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('mm') {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('app_language') ?? 'mm';
  }
  void set(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', value);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});