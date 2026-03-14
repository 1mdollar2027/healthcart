import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});
  @override State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<dynamic> _prescriptions = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final r = await ApiService.listPrescriptions();
      if (mounted) setState(() { _prescriptions = r['items'] ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _prescriptions.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.description_rounded, size: 56, color: HealthCartTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No prescriptions yet', style: TextStyle(color: HealthCartTheme.textSecondary, fontSize: 16)),
          ]))
        : RefreshIndicator(onRefresh: _load, child: ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: _prescriptions.length,
            itemBuilder: (_, i) {
              final rx = _prescriptions[i];
              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: HealthCartTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description_rounded, color: HealthCartTheme.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Prescription', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(rx['created_at']?.toString().substring(0, 10) ?? '', style: Theme.of(context).textTheme.bodySmall),
                  ])),
                  if (rx['pdf_url'] != null) IconButton(icon: const Icon(Icons.download_rounded, color: HealthCartTheme.primary), onPressed: () {}),
                ]),
                if (rx['diagnosis'] != null) ...[
                  const SizedBox(height: 10),
                  Text('Diagnosis: ${rx['diagnosis']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
                if (rx['follow_up_date'] != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: HealthCartTheme.warning),
                    const SizedBox(width: 6),
                    Text('Follow-up: ${rx['follow_up_date']}', style: const TextStyle(fontSize: 12, color: HealthCartTheme.warning)),
                  ]),
                ],
              ])));
            },
          )),
    );
  }
}
