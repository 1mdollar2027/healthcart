import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});
  @override State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  Map<String, dynamic> _latest = {};
  List<dynamic> _history = [];
  bool _loading = true;
  bool _simulating = false;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final latest = await ApiService.getLatestVitals();
      final history = await ApiService.getVitalHistory(days: 7);
      if (mounted) setState(() { _latest = latest['vitals'] ?? {}; _history = history['items'] ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _simulate() async {
    setState(() => _simulating = true);
    try {
      final result = await ApiService.simulateIoT();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Simulated!'), backgroundColor: HealthCartTheme.success));
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _simulating = false);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Vitals'), actions: [
        TextButton.icon(
          onPressed: _simulating ? null : _simulate,
          icon: _simulating ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sensors_rounded),
          label: const Text('Simulate IoT'),
        ),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(onRefresh: _load, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Latest Readings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5,
              children: [
                _vitalTile('Blood Pressure', _latest['blood_pressure_systolic']?['value']?.toString() ?? '--', 'mmHg', Icons.favorite_rounded, HealthCartTheme.secondary),
                _vitalTile('Heart Rate', _latest['heart_rate']?['value']?.toString() ?? '--', 'bpm', Icons.monitor_heart_rounded, HealthCartTheme.error),
                _vitalTile('Blood Sugar', _latest['blood_glucose']?['value']?.toString() ?? '--', 'mg/dL', Icons.bloodtype_rounded, HealthCartTheme.warning),
                _vitalTile('SpO2', _latest['spo2']?['value']?.toString() ?? '--', '%', Icons.air_rounded, HealthCartTheme.accent),
                _vitalTile('Temperature', _latest['temperature']?['value']?.toString() ?? '--', '°F', Icons.thermostat_rounded, HealthCartTheme.primary),
                _vitalTile('Weight', _latest['weight']?['value']?.toString() ?? '--', 'kg', Icons.monitor_weight_rounded, HealthCartTheme.primaryLight),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              const Center(child: Text('No readings yet. Use "Simulate IoT" to test.'))
            else ...(_history.take(20).map((v) => ListTile(
              leading: Icon(_iconForType(v['vital_type']), color: HealthCartTheme.primary),
              title: Text('${v['vital_type']} : ${v['value']} ${v['unit']}', style: const TextStyle(fontSize: 13)),
              subtitle: Text(v['recorded_at']?.toString().substring(0, 16) ?? '', style: const TextStyle(fontSize: 11)),
              dense: true,
            ))),
          ]))),
    );
  }

  Widget _vitalTile(String label, String value, String unit, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: HealthCartTheme.divider),
    ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))]),
      const Spacer(),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(unit, style: const TextStyle(fontSize: 11, color: HealthCartTheme.textSecondary))),
      ]),
    ]));
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'blood_pressure_systolic': case 'blood_pressure_diastolic': return Icons.favorite_rounded;
      case 'heart_rate': return Icons.monitor_heart_rounded;
      case 'blood_glucose': return Icons.bloodtype_rounded;
      case 'spo2': return Icons.air_rounded;
      case 'temperature': return Icons.thermostat_rounded;
      default: return Icons.health_and_safety_rounded;
    }
  }
}
