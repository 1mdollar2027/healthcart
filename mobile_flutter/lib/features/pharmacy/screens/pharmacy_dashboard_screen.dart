import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme.dart';

class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [HealthCartTheme.accent, Color(0xFF009688)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(auth.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () => auth.logout()),
            ]),
            const Text('Pharmacy Dashboard', style: TextStyle(color: Colors.white70)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _stat('New Orders', '0', Icons.shopping_bag_rounded, HealthCartTheme.secondary),
            const SizedBox(width: 10),
            _stat('Preparing', '0', Icons.inventory_2_rounded, HealthCartTheme.warning),
            const SizedBox(width: 10),
            _stat('Delivered', '0', Icons.local_shipping_rounded, HealthCartTheme.success),
          ]),
          const SizedBox(height: 24),
          Text('Actions', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _action(Icons.shopping_bag_rounded, 'View Orders', 'Manage incoming orders'),
          _action(Icons.inventory_rounded, 'Manage Inventory', 'Update stock and medicines'),
          _action(Icons.local_shipping_rounded, 'Delivery Tracking', 'Track dispatched orders'),
          _action(Icons.analytics_rounded, 'Sales Analytics', 'View sales reports'),
        ]))),
      ]),
    );
  }

  Widget _stat(String l, String v, IconData i, Color c) => Expanded(child: Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [Icon(i, color: c, size: 22), const SizedBox(height: 6), Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c)), Text(l, style: const TextStyle(fontSize: 10))]),
  ));

  Widget _action(IconData i, String t, String d) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
    leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: HealthCartTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(i, color: HealthCartTheme.accent)),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(d, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () {},
  ));
}
