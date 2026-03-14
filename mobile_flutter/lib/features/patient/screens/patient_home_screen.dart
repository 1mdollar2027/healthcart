import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});
  @override State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  Map<String, dynamic>? _latestVitals;
  List<dynamic> _upcomingAppointments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final vitals = await ApiService.getLatestVitals();
      final appts = await ApiService.listAppointments(upcoming: true);
      if (mounted) setState(() {
        _latestVitals = vitals['vitals'];
        _upcomingAppointments = (appts['items'] as List?)?.take(3).toList() ?? [];
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [HealthCartTheme.primary, HealthCartTheme.primaryLight],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: Colors.white24,
                    child: Text(auth.fullName.isNotEmpty ? auth.fullName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hello, ${auth.fullName.split(' ').first} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    const Text('How are you feeling today?',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                  IconButton(icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                    onPressed: () => context.go('/patient/notifications')),
                ]),
                const SizedBox(height: 20),
                // Search bar
                GestureDetector(
                  onTap: () => context.go('/patient/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Row(children: [
                      Icon(Icons.search_rounded, color: HealthCartTheme.textSecondary),
                      SizedBox(width: 12),
                      Text('Search doctors, clinics, tests...', style: TextStyle(color: HealthCartTheme.textSecondary, fontSize: 15)),
                    ]),
                  ),
                ),
              ]),
            )),

            // ── Quick Actions Grid ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
                  children: [
                    _quickAction(context, Icons.video_call_rounded, 'Video\nConsult', HealthCartTheme.primary, () => context.go('/patient/search')),
                    _quickAction(context, Icons.local_pharmacy_rounded, 'Order\nMedicine', HealthCartTheme.accent, () => context.go('/patient/pharmacy')),
                    _quickAction(context, Icons.science_rounded, 'Book\nLab Test', HealthCartTheme.warning, () => context.go('/patient/labs')),
                    _quickAction(context, Icons.monitor_heart_rounded, 'Track\nVitals', HealthCartTheme.secondary, () => context.go('/patient/vitals')),
                    _quickAction(context, Icons.description_rounded, 'My\nRx', HealthCartTheme.primary, () => context.go('/patient/prescriptions')),
                    _quickAction(context, Icons.local_hospital_rounded, 'Find\nClinic', HealthCartTheme.primaryLight, () => context.go('/patient/search')),
                    _quickAction(context, Icons.home_rounded, 'Home\nCollect', HealthCartTheme.accent, () => context.go('/patient/labs')),
                    _quickAction(context, Icons.calendar_month_rounded, 'My\nBookings', HealthCartTheme.warning, () {}),
                  ],
                ),
              ]),
            )),

            // ── Upcoming Appointments ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Upcoming Appointments', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (_loading) const Center(child: CircularProgressIndicator())
                else if (_upcomingAppointments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HealthCartTheme.divider),
                    ),
                    child: const Column(children: [
                      Icon(Icons.event_available_rounded, size: 40, color: HealthCartTheme.textSecondary),
                      SizedBox(height: 8),
                      Text('No upcoming appointments', style: TextStyle(color: HealthCartTheme.textSecondary)),
                      SizedBox(height: 4),
                      Text('Book a doctor consultation now!', style: TextStyle(color: HealthCartTheme.textSecondary, fontSize: 12)),
                    ]),
                  )
                else ..._upcomingAppointments.map((a) => _appointmentCard(context, a)),
                const SizedBox(height: 24),
              ]),
            )),

            // ── Vitals Summary ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Health Vitals', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(onPressed: () => context.go('/patient/vitals'), child: const Text('View All →')),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _vitalCard('BP', _latestVitals?['blood_pressure_systolic']?['value']?.toString() ?? '--', 'mmHg', HealthCartTheme.secondary),
                  const SizedBox(width: 10),
                  _vitalCard('Sugar', _latestVitals?['blood_glucose']?['value']?.toString() ?? '--', 'mg/dL', HealthCartTheme.warning),
                  const SizedBox(width: 10),
                  _vitalCard('HR', _latestVitals?['heart_rate']?['value']?.toString() ?? '--', 'bpm', HealthCartTheme.accent),
                ]),
                const SizedBox(height: 40),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2)),
      ]),
    );
  }

  Widget _appointmentCard(BuildContext context, Map<String, dynamic> appt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: HealthCartTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.video_call_rounded, color: HealthCartTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appt['doctor_name'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('${appt['appointment_date']} at ${appt['appointment_time']}', style: Theme.of(context).textTheme.bodySmall),
          ])),
          Chip(
            label: Text(appt['status'] ?? '', style: const TextStyle(fontSize: 11)),
            backgroundColor: appt['status'] == 'confirmed' ? HealthCartTheme.success.withOpacity(0.15) : HealthCartTheme.warning.withOpacity(0.15),
          ),
        ]),
      ),
    );
  }

  Widget _vitalCard(String label, String value, String unit, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealthCartTheme.divider),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: HealthCartTheme.textPrimary)),
        Text(unit, style: const TextStyle(fontSize: 11, color: HealthCartTheme.textSecondary)),
      ]),
    ));
  }
}
