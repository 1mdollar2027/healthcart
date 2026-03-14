import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme.dart';

class ClinicDashboardScreen extends StatelessWidget {
  const ClinicDashboardScreen({super.key});

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [HealthCartTheme.primary, HealthCartTheme.primaryLight]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(auth.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () => auth.logout()),
            ]),
            const SizedBox(height: 4),
            const Text('Clinic / Hospital Dashboard', style: TextStyle(color: Colors.white70)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(children: [
            _statTile('Doctors', '0', Icons.medical_services_rounded, HealthCartTheme.primary),
            const SizedBox(width: 10),
            _statTile('Appointments', '0', Icons.calendar_month_rounded, HealthCartTheme.accent),
            const SizedBox(width: 10),
            _statTile('Revenue', '₹0', Icons.currency_rupee_rounded, HealthCartTheme.success),
          ]),
          const SizedBox(height: 24),
          Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _actionItem(Icons.person_add_rounded, 'Add Doctor', 'Assign a doctor to your clinic'),
          _actionItem(Icons.schedule_rounded, 'Manage Slots', 'Configure consultation time slots'),
          _actionItem(Icons.calendar_today_rounded, 'View Appointments', 'See all upcoming appointments'),
          _actionItem(Icons.analytics_rounded, 'Revenue Analytics', 'View earnings and reports'),
        ]))),
      ]),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Icon(icon, color: color, size: 24), const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: HealthCartTheme.textSecondary)),
    ]),
  ));

  Widget _actionItem(IconData icon, String title, String desc) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
    leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: HealthCartTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: HealthCartTheme.primary)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () {},
  ));
}
