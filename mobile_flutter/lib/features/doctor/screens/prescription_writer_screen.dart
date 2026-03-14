import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class PrescriptionWriterScreen extends StatefulWidget {
  final String appointmentId;
  const PrescriptionWriterScreen({super.key, required this.appointmentId});
  @override State<PrescriptionWriterScreen> createState() => _PrescriptionWriterScreenState();
}

class _PrescriptionWriterScreenState extends State<PrescriptionWriterScreen> {
  final _diagnosisController = TextEditingController();
  final _adviceController = TextEditingController();
  final _medicines = <Map<String, TextEditingController>>[];
  bool _loading = false;

  void _addMedicine() => setState(() => _medicines.add({
    'name': TextEditingController(), 'dosage': TextEditingController(),
    'frequency': TextEditingController(text: '1-0-1'), 'duration': TextEditingController(text: '5 days'),
    'instructions': TextEditingController(),
  }));

  @override void initState() { super.initState(); _addMedicine(); }

  Future<void> _submit() async {
    if (_diagnosisController.text.isEmpty || _medicines.any((m) => m['name']!.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill diagnosis and at least one medicine'))); return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.createPrescription({
        'appointment_id': widget.appointmentId,
        'diagnosis': _diagnosisController.text,
        'advice': _adviceController.text,
        'items': _medicines.map((m) => {
          'medicine_name': m['name']!.text, 'dosage': m['dosage']!.text,
          'frequency': m['frequency']!.text, 'duration': m['duration']!.text,
          'instructions': m['instructions']!.text,
        }).toList(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription created!'), backgroundColor: HealthCartTheme.success));
        context.go('/doctor'); }
    } catch (e) { setState(() => _loading = false); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write Prescription')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Diagnosis', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextField(controller: _diagnosisController, decoration: const InputDecoration(hintText: 'e.g. Viral fever, Upper respiratory infection'), maxLines: 2),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Medicines', style: Theme.of(context).textTheme.headlineSmall),
          TextButton.icon(onPressed: _addMedicine, icon: const Icon(Icons.add_circle_rounded), label: const Text('Add')),
        ]),
        ..._medicines.asMap().entries.map((e) => _medicineCard(e.key, e.value)),
        const SizedBox(height: 20),
        Text('Advice', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextField(controller: _adviceController, decoration: const InputDecoration(hintText: 'Drink warm water, rest for 2 days...'), maxLines: 3),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Generate Prescription & PDF', style: TextStyle(fontSize: 16)),
        )),
      ])),
    );
  }

  Widget _medicineCard(int index, Map<String, TextEditingController> m) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    Row(children: [
      Expanded(child: Text('Medicine ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600))),
      if (_medicines.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: HealthCartTheme.error, size: 20),
        onPressed: () => setState(() => _medicines.removeAt(index))),
    ]),
    const SizedBox(height: 8),
    TextField(controller: m['name'], decoration: const InputDecoration(hintText: 'Medicine name', isDense: true)),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: TextField(controller: m['dosage'], decoration: const InputDecoration(hintText: 'Dosage', isDense: true))),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: m['frequency'], decoration: const InputDecoration(hintText: 'Frequency', isDense: true))),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: TextField(controller: m['duration'], decoration: const InputDecoration(hintText: 'Duration', isDense: true))),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: m['instructions'], decoration: const InputDecoration(hintText: 'Instructions', isDense: true))),
    ]),
  ])));
}
