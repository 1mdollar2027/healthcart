import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});
  @override State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pending = [], _confirmed = [], _completed = [];
  bool _loading = true;

  @override void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); _load(); }
  @override void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final p = await ApiService.listAppointments(status: 'pending');
      final c = await ApiService.listAppointments(status: 'confirmed');
      final d = await ApiService.listAppointments(status: 'completed');
      if (mounted) setState(() { _pending = p['items'] ?? []; _confirmed = c['items'] ?? []; _completed = d['items'] ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments'), bottom: TabBar(controller: _tabController, tabs: [
        Tab(text: 'Pending (${_pending.length})'), Tab(text: 'Confirmed (${_confirmed.length})'), Tab(text: 'Done (${_completed.length})'),
      ])),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabController, children: [
            _list(_pending, 'pending'), _list(_confirmed, 'confirmed'), _list(_completed, 'completed'),
          ]),
    );
  }

  Widget _list(List<dynamic> items, String status) => items.isEmpty
    ? const Center(child: Text('No appointments')) : RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, i) {
        final a = items[i];
        return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 20, backgroundColor: HealthCartTheme.primary.withOpacity(0.1),
              child: Text((a['patient_name'] ?? 'P')[0], style: const TextStyle(color: HealthCartTheme.primary, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['patient_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${a['appointment_date']} at ${a['appointment_time']}', style: const TextStyle(fontSize: 12, color: HealthCartTheme.textSecondary)),
              if (a['reason'] != null) Text('Reason: ${a['reason']}', style: const TextStyle(fontSize: 12)),
            ])),
          ]),
          if (status == 'pending') ...[const SizedBox(height: 10), Row(children: [
            Expanded(child: OutlinedButton(onPressed: () async {
              await ApiService.updateAppointment(a['id'], {'status': 'cancelled'}); _load();
            }, child: const Text('Decline'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: () async {
              await ApiService.updateAppointment(a['id'], {'status': 'confirmed'}); _load();
            }, child: const Text('Accept'))),
          ])],
        ])));
      }));
}
