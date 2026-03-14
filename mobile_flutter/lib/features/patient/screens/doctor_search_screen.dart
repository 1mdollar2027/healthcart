import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});
  @override State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  List<dynamic> _doctors = [];
  bool _loading = true;
  String? _selectedSpec;
  final _searchController = TextEditingController();

  final _specializations = [
    'All', 'General Medicine', 'Cardiology', 'Dermatology', 'Orthopedics',
    'Pediatrics', 'Gynecology', 'ENT', 'Ophthalmology', 'Neurology', 'Psychiatry',
  ];

  @override void initState() { super.initState(); _loadDoctors(); }

  Future<void> _loadDoctors() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.searchDoctors(
        specialization: _selectedSpec != 'All' ? _selectedSpec : null,
      );
      if (mounted) setState(() { _doctors = result['items'] ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor'), actions: [
        IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
      ]),
      body: Column(children: [
        // Search
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or specialization',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _loadDoctors(); })
              : null,
          ),
          onSubmitted: (_) => _loadDoctors(),
        )),
        // Specialization chips
        SizedBox(height: 40, child: ListView.builder(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _specializations.length,
          itemBuilder: (_, i) {
            final spec = _specializations[i];
            final isSelected = _selectedSpec == spec || (spec == 'All' && _selectedSpec == null);
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
              label: Text(spec, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : HealthCartTheme.textPrimary)),
              selected: isSelected,
              selectedColor: HealthCartTheme.primary,
              onSelected: (_) { setState(() => _selectedSpec = spec == 'All' ? null : spec); _loadDoctors(); },
            ));
          },
        )),
        const SizedBox(height: 8),
        // Doctor list
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _doctors.isEmpty
              ? const Center(child: Text('No doctors found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _doctors.length,
                  itemBuilder: (_, i) => _doctorCard(context, _doctors[i]),
                ),
        ),
      ]),
    );
  }

  Widget _doctorCard(BuildContext context, Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/patient/doctor/${doc['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(radius: 28, backgroundColor: HealthCartTheme.primary.withOpacity(0.1),
            backgroundImage: doc['avatar_url'] != null ? NetworkImage(doc['avatar_url']) : null,
            child: doc['avatar_url'] == null
              ? Text((doc['full_name'] ?? 'D')[0], style: const TextStyle(color: HealthCartTheme.primary, fontWeight: FontWeight.w700, fontSize: 20))
              : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc['full_name'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text(doc['specialization'] ?? '', style: TextStyle(color: HealthCartTheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              Text(' ${doc['average_rating']?.toStringAsFixed(1) ?? '0.0'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('${doc['experience_years'] ?? 0} yrs exp', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ])),
          Column(children: [
            Text('₹${(doc['consultation_fee'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: HealthCartTheme.primary)),
            const SizedBox(height: 4),
            if (doc['available_for_video'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: HealthCartTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.videocam_rounded, size: 13, color: HealthCartTheme.accent),
                  SizedBox(width: 3),
                  Text('Video', style: TextStyle(fontSize: 10, color: HealthCartTheme.accent, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ])),
      ),
    );
  }
}
