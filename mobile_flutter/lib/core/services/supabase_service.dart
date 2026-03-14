import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // TODO: Replace with actual Supabase project URL and keys
  static const String url = 'https://your-supabase-url.supabase.co';
  static const String anonKey = 'your-supabase-anon-key';
  static const String apiBaseUrl = 'https://your-api-url.com/api/v1';

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  static String? get accessToken => client.auth.currentSession?.accessToken;

  /// Sign in with phone OTP
  static Future<void> signInWithPhone(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  /// Verify OTP
  static Future<AuthResponse> verifyOTP(String phone, String otp) async {
    return await client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: otp,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
    return response;
  }

  /// Create user profile
  static Future<Map<String, dynamic>> createProfile({
    required String fullName,
    required String role,
    String? phone,
    String? email,
  }) async {
    final response = await client.from('profiles').insert({
      'id': currentUser!.id,
      'full_name': fullName,
      'role': role,
      'phone': phone ?? currentUser!.phone,
      'email': email,
      'consent_given': true,
    }).select().single();
    return response;
  }

  /// Update FCM token
  static Future<void> updateFcmToken(String token) async {
    if (currentUser == null) return;
    await client.from('profiles').update({
      'fcm_token': token,
    }).eq('id', currentUser!.id);
  }
}
