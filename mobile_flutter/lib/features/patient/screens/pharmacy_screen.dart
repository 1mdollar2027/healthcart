import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});
  @override State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  List<dynamic> _pharmacies = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await ApiService.listPharmacies(); if (mounted) setState(() { _pharmacies = r['items'] ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Medicines')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Text('Nearby Pharmacies', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ..._pharmacies.map((p) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: HealthCartTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_pharmacy_rounded, color: HealthCartTheme.accent)),
          title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${p['address_line'] ?? ''}\n${p['delivery_available'] == true ? '🚚 Delivery available (${p['delivery_radius_km'] ?? 10} km)' : 'Pickup only'}', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded),
          isThreeLine: true,
          onTap: () {},
        ))),
      ]),
    );
  }
}
