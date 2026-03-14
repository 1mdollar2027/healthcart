import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'api_service.dart';

/// Global auth state provider.
class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _profile;
  String? _role;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get profile => _profile;
  String get role => _role ?? 'patient';
  String get userId => SupabaseService.currentUser?.id ?? '';
  String get fullName => _profile?['full_name'] ?? '';
  bool get isNewUser => _profile == null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        _isAuthenticated = true;
        await _loadProfile();
      } else {
        _isAuthenticated = false;
        _profile = null;
        _role = null;
      }
      _isLoading = false;
      notifyListeners();
    });

    // Check current session
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      _isAuthenticated = true;
      await _loadProfile();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await SupabaseService.getProfile();
      _role = _profile?['role'];
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> sendOTP(String phone) async {
    await SupabaseService.signInWithPhone(phone);
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    try {
      final response = await SupabaseService.verifyOTP(phone, otp);
      if (response.session != null) {
        _isAuthenticated = true;
        await _loadProfile();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return false;
    }
  }

  Future<void> createProfile({
    required String fullName,
    required String role,
  }) async {
    _profile = await SupabaseService.createProfile(
      fullName: fullName,
      role: role,
    );
    _role = role;
    notifyListeners();
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    _isAuthenticated = false;
    _profile = null;
    _role = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
    notifyListeners();
  }
}
