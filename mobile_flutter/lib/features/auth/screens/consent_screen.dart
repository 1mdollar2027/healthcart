import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.shield_rounded, color: HealthCartTheme.primary, size: 56),
              const SizedBox(height: 20),
              Text('Data Privacy & Consent', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'HealthCart is committed to protecting your personal health data in compliance with the Digital Personal Data Protection Act, 2023 (DPDP Act).',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _consentItem(context, Icons.lock_rounded, 'Encrypted Storage', 'Your health records are encrypted at rest and in transit.'),
              _consentItem(context, Icons.visibility_off_rounded, 'Minimal Access', 'Only your assigned doctors can view your medical data.'),
              _consentItem(context, Icons.delete_forever_rounded, 'Right to Erasure', 'You can request deletion of your data at any time.'),
              _consentItem(context, Icons.gavel_rounded, 'DPDP Compliant', 'We follow all provisions of India\'s DPDP Act 2023.'),
              const Spacer(),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How we handle your data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildConsentPoint(
                      icon: Icons.health_and_safety,
                      title: 'Health Data (DPDP Act 2023)',
                      description: 'We collect your vitals and medical history solely to provide telemedicine services. Your data is encrypted and never sold.',
                    ),
                    _buildConsentPoint(
                      icon: Icons.video_camera_front,
                      title: 'Video Consultations',
                      description: 'Consultations are conducted over secure, ephemeral channels. We do not record or store your video streams.',
                    ),
                    _buildConsentPoint(
                      icon: Icons.notifications_active,
                      title: 'IoT & Vitals Alerts',
                      description: 'Continuous monitoring data is used to trigger life-saving alerts to you and your assigned doctor.',
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          final url = Uri.parse('https://api.healthcart.in/privacy');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Text(
                          'Read Full Privacy Policy',
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Added some spacing
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Record consent and navigate to home
                    final role = auth.role;
                    switch (role) {
                      case 'doctor': context.go('/doctor');
                      case 'clinic_admin': context.go('/clinic');
                      case 'lab_admin': context.go('/lab');
                      case 'pharmacy_admin': context.go('/pharmacy');
                      default: context.go('/patient');
                    }
                  },
                  child: const Text('I Agree & Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => auth.logout(),
                child: const Text('Decline & Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _consentItem(BuildContext context, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HealthCartTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: HealthCartTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HealthCartTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
