import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/consent_screen.dart';
import '../features/patient/screens/patient_home_screen.dart';
import '../features/patient/screens/doctor_search_screen.dart';
import '../features/patient/screens/doctor_detail_screen.dart';
import '../features/patient/screens/booking_screen.dart';
import '../features/patient/screens/payment_screen.dart';
import '../features/patient/screens/video_call_screen.dart';
import '../features/patient/screens/prescriptions_screen.dart';
import '../features/patient/screens/vitals_screen.dart';
import '../features/patient/screens/lab_tests_screen.dart';
import '../features/patient/screens/pharmacy_screen.dart';
import '../features/patient/screens/notifications_screen.dart';
import '../features/doctor/screens/doctor_home_screen.dart';
import '../features/doctor/screens/doctor_appointments_screen.dart';
import '../features/doctor/screens/prescription_writer_screen.dart';
import '../features/clinic/screens/clinic_dashboard_screen.dart';
import '../features/lab/screens/lab_dashboard_screen.dart';
import '../features/pharmacy/screens/pharmacy_dashboard_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoading = auth.isLoading;
        if (isLoading) return null;

        final isLoggedIn = auth.isAuthenticated;
        final isNewUser = auth.isNewUser;
        final path = state.matchedLocation;

        // Auth pages
        final isAuthPage = path == '/login' || path == '/role-selection' || path == '/consent';

        if (!isLoggedIn && !isAuthPage) return '/login';
        if (isLoggedIn && isNewUser && path != '/role-selection' && path != '/consent') return '/role-selection';
        if (isLoggedIn && !isNewUser && isAuthPage) {
          return _homeForRole(auth.role);
        }
        return null;
      },
      routes: [
        // ── Auth ──
        GoRoute(path: '/', redirect: (_, __) => '/login'),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(path: '/consent', builder: (_, __) => const ConsentScreen()),

        // ── Patient Routes ──
        ShellRoute(
          builder: (context, state, child) => PatientShell(child: child),
          routes: [
            GoRoute(path: '/patient', builder: (_, __) => const PatientHomeScreen()),
            GoRoute(path: '/patient/search', builder: (_, __) => const DoctorSearchScreen()),
            GoRoute(path: '/patient/doctor/:id', builder: (_, state) =>
              DoctorDetailScreen(doctorId: state.pathParameters['id']!)),
            GoRoute(path: '/patient/book/:doctorId', builder: (_, state) =>
              BookingScreen(doctorId: state.pathParameters['doctorId']!)),
            GoRoute(path: '/patient/pay/:appointmentId', builder: (_, state) =>
              PaymentScreen(appointmentId: state.pathParameters['appointmentId']!)),
            GoRoute(path: '/patient/video/:consultationId', builder: (_, state) =>
              VideoCallScreen(consultationId: state.pathParameters['consultationId']!)),
            GoRoute(path: '/patient/prescriptions', builder: (_, __) => const PrescriptionsScreen()),
            GoRoute(path: '/patient/vitals', builder: (_, __) => const VitalsScreen()),
            GoRoute(path: '/patient/labs', builder: (_, __) => const LabTestsScreen()),
            GoRoute(path: '/patient/pharmacy', builder: (_, __) => const PharmacyScreen()),
            GoRoute(path: '/patient/notifications', builder: (_, __) => const NotificationsScreen()),
          ],
        ),

        // ── Doctor Routes ──
        GoRoute(path: '/doctor', builder: (_, __) => const DoctorHomeScreen()),
        GoRoute(path: '/doctor/appointments', builder: (_, __) => const DoctorAppointmentsScreen()),
        GoRoute(path: '/doctor/prescribe/:appointmentId', builder: (_, state) =>
          PrescriptionWriterScreen(appointmentId: state.pathParameters['appointmentId']!)),

        // ── Clinic Routes ──
        GoRoute(path: '/clinic', builder: (_, __) => const ClinicDashboardScreen()),

        // ── Lab Routes ──
        GoRoute(path: '/lab', builder: (_, __) => const LabDashboardScreen()),

        // ── Pharmacy Routes ──
        GoRoute(path: '/pharmacy', builder: (_, __) => const PharmacyDashboardScreen()),
      ],
    );
  }

  static String _homeForRole(String role) {
    switch (role) {
      case 'doctor': return '/doctor';
      case 'clinic_admin': return '/clinic';
      case 'lab_admin':
      case 'lab_technician': return '/lab';
      case 'pharmacy_admin': return '/pharmacy';
      default: return '/patient';
    }
  }
}

/// Patient shell with bottom navigation
class PatientShell extends StatefulWidget {
  final Widget child;
  const PatientShell({super.key, required this.child});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: context.go('/patient');
            case 1: context.go('/patient/search');
            case 2: context.go('/patient/prescriptions');
            case 3: context.go('/patient/vitals');
            case 4: context.go('/patient/notifications');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Doctors'),
          NavigationDestination(icon: Icon(Icons.description_rounded), label: 'Rx'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_rounded), label: 'Vitals'),
          NavigationDestination(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
        ],
      ),
    );
  }
}
