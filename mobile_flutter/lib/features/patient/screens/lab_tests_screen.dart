import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class LabTestsScreen extends StatefulWidget {
  const LabTestsScreen({super.key});
  @override State<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends State<LabTestsScreen> {
  List<dynamic> _labs = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await ApiService.listLabs(); if (mounted) setState(() { _labs = r['items'] ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Tests')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Text('Available Labs', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ..._labs.map((lab) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: HealthCartTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.science_rounded, color: HealthCartTheme.warning)),
          title: Text(lab['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${lab['address_line'] ?? ''}\n${lab['home_collection_available'] == true ? '🏠 Home collection available' : ''}', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded),
          isThreeLine: true,
          onTap: () {},
        ))),
      ]),
    );
  }
}
