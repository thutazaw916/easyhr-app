import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Development URLs (uncomment for local testing)
// const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator → localhost
// const String baseUrl = 'http://localhost:3000/api/v1'; // iOS simulator

// Production URL
const String baseUrl = 'https://easyhr-api.onrender.com/api/v1';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired - redirect to login
          _storage.deleteAll();
        }
        handler.next(error);
      },
    ));
  }

  // ============================================
  // AUTH
  // ============================================

  Future<Map<String, dynamic>> companySignUp(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/company/signup', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> verifyCompany(String email, String code) async {
    final response = await _dio.post('/auth/company/verify', data: {
      'email': email,
      'verification_code': code,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> setOwnerPassword(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/company/set-password', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final response = await _dio.post('/auth/admin/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final response = await _dio.post('/auth/employee/request-otp', data: {'phone': phone});
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await _dio.post('/auth/employee/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> firebasePhoneLogin(String firebaseIdToken, String phone) async {
    final response = await _dio.post('/auth/employee/firebase-login', data: {
      'firebase_id_token': firebaseIdToken,
      'phone': phone,
    });
    return response.data;
  }

  // ============================================
  // COMPANY
  // ============================================

  Future<Map<String, dynamic>> getCompanyProfile() async {
    final response = await _dio.get('/company/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/company/dashboard');
    return response.data;
  }

  // ============================================
  // EMPLOYEE
  // ============================================

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/employees/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateMySettings(Map<String, dynamic> data) async {
    final response = await _dio.put('/employees/me/settings', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> listEmployees({Map<String, dynamic>? params}) async {
    final response = await _dio.get('/employees', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> addEmployee(Map<String, dynamic> data) async {
    final response = await _dio.post('/employees', data: data);
    return response.data;
  }

  // ============================================
  // ATTENDANCE
  // ============================================

  Future<Map<String, dynamic>> checkIn(double lat, double lng, {String? deviceId}) async {
    final response = await _dio.post('/attendance/check-in', data: {
      'latitude': lat,
      'longitude': lng,
      'device_id': deviceId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkOut(double lat, double lng) async {
    final response = await _dio.post('/attendance/check-out', data: {
      'latitude': lat,
      'longitude': lng,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> qrCheckIn(String qrCode, {double? lat, double? lng}) async {
    final response = await _dio.post('/attendance/qr-check-in', data: {
      'qr_code': qrCode,
      'latitude': lat,
      'longitude': lng,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMyAttendanceStatus({double? lat, double? lng}) async {
    final response = await _dio.get('/attendance/my-status', queryParameters: {
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMyAttendanceHistory({int? month, int? year}) async {
    final response = await _dio.get('/attendance/my-history', queryParameters: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getDailyReport({String? date, String? departmentId}) async {
    final response = await _dio.get('/attendance/daily-report', queryParameters: {
      if (date != null) 'date': date,
      if (departmentId != null) 'department_id': departmentId,
    });
    return response.data;
  }

  // ============================================
  // LEAVE
  // ============================================

  Future<List<dynamic>> getLeaveTypes() async {
    final response = await _dio.get('/leave/types');
    return response.data;
  }

  Future<List<dynamic>> getMyLeaveBalances() async {
    final response = await _dio.get('/leave/my-balances');
    return response.data;
  }

  Future<Map<String, dynamic>> requestLeave(Map<String, dynamic> data) async {
    final response = await _dio.post('/leave/request', data: data);
    return response.data;
  }

  Future<List<dynamic>> getMyLeaveRequests({String? status}) async {
    final response = await _dio.get('/leave/my-requests', queryParameters: {
      if (status != null) 'status': status,
    });
    return response.data;
  }

  Future<List<dynamic>> getPendingLeaves({String? departmentId}) async {
    final response = await _dio.get('/leave/pending', queryParameters: {
      if (departmentId != null) 'department_id': departmentId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> approveLeave(String id) async {
    final response = await _dio.put('/leave/requests/$id/approve');
    return response.data;
  }

  Future<Map<String, dynamic>> rejectLeave(String id, {String? reason}) async {
    final response = await _dio.put('/leave/requests/$id/reject', data: {
      'rejection_reason': reason,
    });
    return response.data;
  }

  // ============================================
  // PAYROLL
  // ============================================

  Future<Map<String, dynamic>> getMyPayslip(int year, int month) async {
    final response = await _dio.get('/payroll/my-payslip', queryParameters: {
      'year': year, 'month': month,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculatePayroll(int year, int month) async {
    final response = await _dio.post('/payroll/calculate', queryParameters: {
      'year': year, 'month': month,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMonthlyPayroll(int year, int month) async {
    final response = await _dio.get('/payroll/monthly', queryParameters: {
      'year': year, 'month': month,
    });
    return response.data;
  }

  // ============================================
  // SALARY STRUCTURE
  // ============================================

  Future<Map<String, dynamic>> setSalaryStructure(String employeeId, Map<String, dynamic> data) async {
    final response = await _dio.post('/payroll/salary-structure/$employeeId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>?> getSalaryStructure(String employeeId) async {
    try {
      final response = await _dio.get('/payroll/salary-structure/$employeeId');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getAllSalaryStructures() async {
    final response = await _dio.get('/payroll/salary-structures');
    return response.data;
  }

  // ============================================
  // DEPARTMENTS / BRANCHES
  // ============================================

  Future<List<dynamic>> getDepartments() async {
    final response = await _dio.get('/departments');
    return response.data;
  }

  Future<List<dynamic>> getBranches() async {
    final response = await _dio.get('/branches');
    return response.data;
  }

  // ============================================
  // AI CHATBOT
  // ============================================

  Future<Map<String, dynamic>> chatbotSend(String message, List<Map<String, String>> history) async {
    final response = await _dio.post('/chatbot/chat', data: {
      'message': message,
      'history': history,
    });
    return response.data;
  }

  Future<List<dynamic>> getChatbotHistory() async {
    final response = await _dio.get('/chatbot/history');
    return response.data;
  }

  Future<void> clearChatbotHistory() async {
    await _dio.delete('/chatbot/history');
  }

  // ============================================
  // BILLING & SUBSCRIPTION
  // ============================================

  Future<Map<String, dynamic>> getPlans() async {
    final response = await _dio.get('/billing/plans');
    return response.data;
  }

  Future<Map<String, dynamic>> getSubscription() async {
    final response = await _dio.get('/billing/subscription');
    return response.data;
  }

  Future<Map<String, dynamic>> submitPayment(Map<String, dynamic> data) async {
    final response = await _dio.post('/billing/pay', data: data);
    return response.data;
  }

  Future<List<dynamic>> getPaymentHistory() async {
    final response = await _dio.get('/billing/payments');
    return response.data;
  }

  // ============================================
  // TOKEN MANAGEMENT
  // ============================================

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> clearToken() async {
    await _storage.deleteAll();
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());