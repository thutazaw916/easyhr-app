import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class FirebasePhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  /// Send OTP to phone number via Firebase
  /// Returns a completer that resolves when verification ID is received
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    // Ensure phone number has country code
    String formattedPhone = phoneNumber.trim();
    if (formattedPhone.startsWith('09')) {
      formattedPhone = '+95${formattedPhone.substring(1)}'; // Myanmar +95
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+95$formattedPhone';
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification (Android only - auto-reads SMS)
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        String msg;
        switch (e.code) {
          case 'invalid-phone-number':
            msg = 'ဖုန်းနံပါတ် မှားနေပါတယ်';
            break;
          case 'too-many-requests':
            msg = 'OTP အကြိမ်ရေ ကျော်လွန်ပါပြီ။ ခဏစောင့်ပါ';
            break;
          case 'quota-exceeded':
            msg = 'SMS quota ကျော်လွန်ပါပြီ';
            break;
          default:
            msg = e.message ?? 'OTP ပို့၍ မရပါ';
        }
        onError(msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Verify OTP code and sign in with Firebase
  /// Returns the Firebase ID token on success
  Future<String?> verifyOtp(String otp) async {
    if (_verificationId == null) {
      throw Exception('No verification ID. Please request OTP first.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    return _signInWithCredential(credential);
  }

  /// Sign in with a PhoneAuthCredential (used for both manual and auto-verify)
  Future<String?> _signInWithCredential(PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    // Get Firebase ID token to send to our backend
    final idToken = await userCredential.user?.getIdToken();
    return idToken;
  }

  /// Sign in with auto-verified credential
  Future<String?> signInWithCredential(PhoneAuthCredential credential) async {
    return _signInWithCredential(credential);
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
