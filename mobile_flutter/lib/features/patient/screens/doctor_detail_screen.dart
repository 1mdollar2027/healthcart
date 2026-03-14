import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});
  @override State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  Map<String, dynamic>? _doctor;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final d = await ApiService.getDoctorDetail(widget.doctorId);
      if (mounted) setState(() { _doctor = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_doctor == null) return const Scaffold(body: Center(child: Text('Doctor not found')));
    final d = _doctor!;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(expandedHeight: 200, pinned: true, flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [HealthCartTheme.primary, HealthCartTheme.primaryLight])),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 40),
              CircleAvatar(radius: 40, backgroundColor: Colors.white24,
                child: Text((d['full_name'] ?? 'D')[0], style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700))),
              const SizedBox(height: 10),
              Text(d['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(d['specialization'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ])),
          ),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats row
          Row(children: [
            _statCard('Rating', '${d['average_rating']?.toStringAsFixed(1) ?? '0.0'} ★', HealthCartTheme.warning),
            const SizedBox(width: 10),
            _statCard('Experience', '${d['experience_years'] ?? 0} yrs', HealthCartTheme.primary),
            const SizedBox(width: 10),
            _statCard('Consults', '${d['total_consultations'] ?? 0}', HealthCartTheme.accent),
          ]),
          const SizedBox(height: 24),
          Text('About', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(d['bio'] ?? 'Experienced medical professional.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          // Details
          _detailRow(Icons.school_rounded, 'Qualification', d['qualification'] ?? ''),
          _detailRow(Icons.badge_rounded, 'Reg. Number', d['registration_number'] ?? ''),
          _detailRow(Icons.language_rounded, 'Languages', (d['languages'] as List?)?.join(', ') ?? 'Hindi, English'),
          _detailRow(Icons.currency_rupee_rounded, 'Consultation Fee', '₹${(d['consultation_fee'] ?? 0).toStringAsFixed(0)}'),
          const SizedBox(height: 30),
        ]))),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Consultation Fee', style: TextStyle(fontSize: 12, color: HealthCartTheme.textSecondary)),
            Text('₹${(d['consultation_fee'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: HealthCartTheme.primary)),
          ])),
          SizedBox(width: 180, height: 50, child: ElevatedButton(
            onPressed: () => context.go('/patient/book/${widget.doctorId}'),
            child: const Text('Book Now'),
          )),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: HealthCartTheme.textSecondary)),
    ]),
  ));

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, size: 20, color: HealthCartTheme.primary),
      const SizedBox(width: 12),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: HealthCartTheme.textSecondary))),
    ]),
  );
}
