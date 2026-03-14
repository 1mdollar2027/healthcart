import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  final _nameController = TextEditingController();
  bool _loading = false;

  final _roles = [
    {'value': 'patient', 'label': 'Patient', 'icon': Icons.person_rounded, 'desc': 'Book doctors, order medicines, track health'},
    {'value': 'doctor', 'label': 'Doctor', 'icon': Icons.medical_services_rounded, 'desc': 'Manage appointments, video consult, prescribe'},
    {'value': 'clinic_admin', 'label': 'Clinic / Hospital', 'icon': Icons.local_hospital_rounded, 'desc': 'Manage doctors, slots, revenue'},
    {'value': 'lab_admin', 'label': 'Lab / Diagnostics', 'icon': Icons.science_rounded, 'desc': 'Manage tests, collections, results'},
    {'value': 'pharmacy_admin', 'label': 'Pharmacy', 'icon': Icons.local_pharmacy_rounded, 'desc': 'Manage orders, inventory, delivery'},
  ];

  Future<void> _proceed() async {
    if (_selectedRole == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and select a role')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.createProfile(
        fullName: _nameController.text.trim(),
        role: _selectedRole!,
      );
      if (mounted) context.go('/consent');
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('What\'s your name?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Text('I am a...', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['value'];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = role['value'] as String),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? HealthCartTheme.primary.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? HealthCartTheme.primary : HealthCartTheme.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? HealthCartTheme.primary : HealthCartTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(role['icon'] as IconData, color: isSelected ? Colors.white : HealthCartTheme.primary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role['label'] as String, style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15,
                                      color: isSelected ? HealthCartTheme.primary : HealthCartTheme.textPrimary,
                                    )),
                                    const SizedBox(height: 2),
                                    Text(role['desc'] as String, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: HealthCartTheme.primary, size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _proceed,
                  child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
