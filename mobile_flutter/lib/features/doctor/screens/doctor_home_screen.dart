import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});
  @override State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  List<dynamic> _todayAppointments = [];
  bool _loading = true;
  int _pendingCount = 0;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final appts = await ApiService.listAppointments(status: 'confirmed');
      if (mounted) setState(() { _todayAppointments = appts['items'] ?? []; _pendingCount = _todayAppointments.where((a) => a['status'] == 'pending').length; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: RefreshIndicator(onRefresh: _load, child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [HealthCartTheme.primary, HealthCartTheme.primaryLight]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.white24,
                child: Text(auth.fullName.isNotEmpty ? auth.fullName[0] : 'D', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. ${auth.fullName}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const Text('Doctor Dashboard', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () => auth.logout()),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              _statCard('Today', '${_todayAppointments.length}', Icons.calendar_today_rounded),
              const SizedBox(width: 12),
              _statCard('Pending', '$_pendingCount', Icons.pending_actions_rounded),
              const SizedBox(width: 12),
              _statCard('Completed', '${_todayAppointments.where((a) => a['status'] == 'completed').length}', Icons.check_circle_rounded),
            ]),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _actionBtn('View\nAppointments', Icons.calendar_month_rounded, HealthCartTheme.primary, () => context.go('/doctor/appointments')),
            const SizedBox(width: 12),
            _actionBtn('My\nSchedule', Icons.schedule_rounded, HealthCartTheme.accent, () {}),
            const SizedBox(width: 12),
            _actionBtn('Patient\nHistory', Icons.history_rounded, HealthCartTheme.warning, () {}),
          ]),
          const SizedBox(height: 24),
          Text("Today's Appointments", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator())
          else if (_todayAppointments.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No appointments today')))
          else ..._todayAppointments.map((a) => _appointmentTile(context, a)),
        ]))),
      ])),
    );
  }

  Widget _statCard(String label, String value, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Icon(icon, color: Colors.white70, size: 20), const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]),
  ));

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color))])),
  ));

  Widget _appointmentTile(BuildContext context, Map<String, dynamic> a) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14),
    child: Row(children: [
      CircleAvatar(radius: 22, backgroundColor: HealthCartTheme.accent.withOpacity(0.1),
        child: Text((a['patient_name'] ?? 'P')[0], style: const TextStyle(fontWeight: FontWeight.w600, color: HealthCartTheme.accent))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a['patient_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text('${a['appointment_time']} • ${a['reason'] ?? 'Consultation'}', style: const TextStyle(fontSize: 12, color: HealthCartTheme.textSecondary)),
      ])),
      if (a['status'] == 'confirmed') SizedBox(height: 36, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: HealthCartTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 12)),
        onPressed: () async {
          try { final c = await ApiService.startConsultation(a['id']); if (mounted) context.go('/patient/video/${c['consultation_id']}');
          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
        },
        child: const Text('Start', style: TextStyle(fontSize: 12)),
      ))
      else if (a['status'] == 'completed')
        TextButton(onPressed: () => context.go('/doctor/prescribe/${a['id']}'), child: const Text('Write Rx', style: TextStyle(fontSize: 12))),
    ]),
  ));
}
