import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

/// Centralized API service for communicating with the FastAPI backend.
class ApiService {
  static String get baseUrl => SupabaseService.apiBaseUrl;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (SupabaseService.accessToken != null)
      'Authorization': 'Bearer ${SupabaseService.accessToken}',
  };

  // ── Generic HTTP methods ──

  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'message': 'Success'};
      return jsonDecode(response.body);
    } else {
      final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw ApiException(
        statusCode: response.statusCode,
        message: error['detail'] ?? 'Something went wrong',
      );
    }
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> getProfile() => get('/auth/profile');
  static Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) => post('/auth/profile', body: data);
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) => patch('/auth/profile', body: data);

  // ── Doctors ──
  static Future<Map<String, dynamic>> searchDoctors({
    String? specialization, String? city, int page = 1,
  }) => get('/bookings/doctors', queryParams: {
    if (specialization != null) 'specialization': specialization,
    if (city != null) 'city': city,
    'page': page.toString(),
  });

  static Future<Map<String, dynamic>> getDoctorDetail(String doctorId) =>
    get('/bookings/doctors/$doctorId');

  static Future<Map<String, dynamic>> getDoctorSlots(String doctorId, String date) =>
    get('/bookings/doctors/$doctorId/slots', queryParams: {'target_date': date});

  // ── Appointments ──
  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) =>
    post('/bookings/appointments', body: data);

  static Future<Map<String, dynamic>> listAppointments({String? status, bool upcoming = false}) =>
    get('/bookings/appointments', queryParams: {
      if (status != null) 'status': status,
      'upcoming': upcoming.toString(),
    });

  static Future<Map<String, dynamic>> updateAppointment(String id, Map<String, dynamic> data) =>
    patch('/bookings/appointments/$id', body: data);

  // ── Payments ──
  static Future<Map<String, dynamic>> createPaymentOrder(Map<String, dynamic> data) =>
    post('/payments/create-order', body: data);

  static Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) =>
    post('/payments/verify', body: data);

  // ── Consultations ──
  static Future<Map<String, dynamic>> startConsultation(String appointmentId) =>
    post('/consultations/start', body: {'appointment_id': appointmentId});

  static Future<Map<String, dynamic>> getConsultationToken(String consultationId) =>
    get('/consultations/$consultationId/token');

  static Future<Map<String, dynamic>> endConsultation(String consultationId, Map<String, dynamic> data) =>
    post('/consultations/$consultationId/end', body: data);

  // ── Prescriptions ──
  static Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) =>
    post('/prescriptions/', body: data);

  static Future<Map<String, dynamic>> listPrescriptions() =>
    get('/prescriptions/');

  static Future<Map<String, dynamic>> getPrescription(String id) =>
    get('/prescriptions/$id');

  // ── Labs ──
  static Future<Map<String, dynamic>> listLabs() => get('/labs/');
  static Future<Map<String, dynamic>> listLabTests(String labId) => get('/labs/$labId/tests');
  static Future<Map<String, dynamic>> createLabBooking(Map<String, dynamic> data) =>
    post('/labs/bookings', body: data);
  static Future<Map<String, dynamic>> listLabBookings() => get('/labs/bookings');
  static Future<Map<String, dynamic>> getLabResults(String bookingId) =>
    get('/labs/results/$bookingId');

  // ── Pharmacies ──
  static Future<Map<String, dynamic>> listPharmacies() => get('/pharmacies/');
  static Future<Map<String, dynamic>> listMedicines(String pharmacyId) =>
    get('/pharmacies/$pharmacyId/medicines');
  static Future<Map<String, dynamic>> createPharmacyOrder(Map<String, dynamic> data) =>
    post('/pharmacies/orders', body: data);
  static Future<Map<String, dynamic>> listPharmacyOrders() => get('/pharmacies/orders');

  // ── Vitals ──
  static Future<Map<String, dynamic>> recordVital(Map<String, dynamic> data) =>
    post('/vitals/record', body: data);
  static Future<Map<String, dynamic>> getVitalHistory({String? vitalType, int days = 30}) =>
    get('/vitals/history', queryParams: {
      if (vitalType != null) 'vital_type': vitalType,
      'days': days.toString(),
    });
  static Future<Map<String, dynamic>> getLatestVitals() => get('/vitals/latest');
  static Future<Map<String, dynamic>> simulateIoT() => post('/vitals/simulate-iot');

  // ── Notifications ──
  static Future<Map<String, dynamic>> listNotifications({bool unreadOnly = false}) =>
    get('/notifications/', queryParams: {'unread_only': unreadOnly.toString()});
  static Future<Map<String, dynamic>> markNotificationRead(String id) =>
    post('/notifications/$id/read');
  static Future<Map<String, dynamic>> markAllNotificationsRead() =>
    post('/notifications/read-all');
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
