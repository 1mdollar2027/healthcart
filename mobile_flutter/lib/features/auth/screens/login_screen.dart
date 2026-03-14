import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_provider.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.sendOTP('+91${_phoneController.text}');
      setState(() { _otpSent = true; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.verifyOTP('+91${_phoneController.text}', _otpController.text);
      setState(() => _loading = false);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [HealthCartTheme.primary, HealthCartTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineLarge,
                        children: const [
                          TextSpan(text: 'Health', style: TextStyle(color: HealthCartTheme.primary)),
                          TextSpan(text: 'Cart', style: TextStyle(color: HealthCartTheme.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Health, One Tap Away',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Title
                Text(
                  _otpSent ? 'Enter OTP' : 'Get Started',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _otpSent
                    ? 'We sent a 6-digit code to +91 ${_phoneController.text}'
                    : 'Enter your mobile number to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                if (!_otpSent) ...[
                  // Phone input
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2),
                    decoration: InputDecoration(
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 6),
                            Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      hintText: '98765 43210',
                      counterText: '',
                    ),
                  ),
                ] else ...[
                  // OTP input
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12),
                    decoration: const InputDecoration(
                      hintText: '● ● ● ● ● ●',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : () => setState(() => _otpSent = false),
                    child: const Text('← Change phone number'),
                  ),
                ],

                const SizedBox(height: 24),

                // CTA Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                    child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_otpSent ? 'Verify OTP' : 'Send OTP', style: const TextStyle(fontSize: 17)),
                  ),
                ),

                const Spacer(),

                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'By continuing, you agree to our Terms of Service and\nData Privacy Policy (DPDP Act 2023 compliant)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
