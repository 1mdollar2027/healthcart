import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class BookingScreen extends StatefulWidget {
  final String doctorId;
  const BookingScreen({super.key, required this.doctorId});
  @override State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  String _reason = '';
  bool _loading = false;
  Map<String, dynamic>? _doctor;
  List<String> _bookedTimes = [];

  final _times = ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '12:00', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00'];

  @override void initState() { super.initState(); _loadDoctor(); _loadSlots(); }

  Future<void> _loadDoctor() async {
    try {
      final d = await ApiService.getDoctorDetail(widget.doctorId);
      if (mounted) setState(() => _doctor = d);
    } catch (_) {}
  }

  Future<void> _loadSlots() async {
    try {
      final s = await ApiService.getDoctorSlots(widget.doctorId, DateFormat('yyyy-MM-dd').format(_selectedDate));
      if (mounted) setState(() => _bookedTimes = List<String>.from(s['booked_times'] ?? []));
    } catch (_) {}
  }

  Future<void> _bookAppointment() async {
    if (_selectedTime == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a time slot'))); return; }
    setState(() => _loading = true);
    try {
      final result = await ApiService.createAppointment({
        'doctor_id': widget.doctorId,
        'appointment_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'appointment_time': '$_selectedTime:00',
        'consultation_type': 'video',
        'reason': _reason.isNotEmpty ? _reason : null,
      });
      if (mounted) context.go('/patient/pay/${result['id']}');
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_doctor != null) Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(radius: 24, backgroundColor: HealthCartTheme.primary.withOpacity(0.1),
            child: Text((_doctor!['full_name'] ?? 'D')[0], style: const TextStyle(color: HealthCartTheme.primary, fontWeight: FontWeight.w700))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_doctor!['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(_doctor!['specialization'] ?? '', style: Theme.of(context).textTheme.bodySmall),
          ])),
          Text('₹${(_doctor!['consultation_fee'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: HealthCartTheme.primary, fontSize: 18)),
        ]))),
        const SizedBox(height: 24),
        Text('Select Date', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        SizedBox(height: 80, child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: 14,
          itemBuilder: (_, i) {
            final date = DateTime.now().add(Duration(days: i + 1));
            final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
            return GestureDetector(
              onTap: () { setState(() { _selectedDate = date; _selectedTime = null; }); _loadSlots(); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 60, margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? HealthCartTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? HealthCartTheme.primary : HealthCartTheme.divider),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(DateFormat('E').format(date), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : HealthCartTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : HealthCartTheme.textPrimary)),
                  Text(DateFormat('MMM').format(date), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : HealthCartTheme.textSecondary)),
                ]),
              ),
            );
          },
        )),
        const SizedBox(height: 24),
        Text('Select Time', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: _times.map((t) {
          final isBooked = _bookedTimes.contains('$t:00');
          final isSelected = _selectedTime == t;
          return ChoiceChip(
            label: Text(t, style: TextStyle(color: isBooked ? HealthCartTheme.textSecondary : isSelected ? Colors.white : HealthCartTheme.textPrimary)),
            selected: isSelected, selectedColor: HealthCartTheme.primary,
            disabledColor: HealthCartTheme.divider,
            onSelected: isBooked ? null : (_) => setState(() => _selectedTime = t),
          );
        }).toList()),
        const SizedBox(height: 24),
        Text('Reason (optional)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(decoration: const InputDecoration(hintText: 'e.g. Fever, headache, follow-up'),
          onChanged: (v) => _reason = v, maxLines: 2),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: _loading ? null : _bookAppointment,
          child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Confirm & Pay', style: TextStyle(fontSize: 16)),
        )),
      ])),
    );
  }
}
