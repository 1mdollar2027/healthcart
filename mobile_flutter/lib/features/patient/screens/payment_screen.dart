import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String appointmentId;
  const PaymentScreen({super.key, required this.appointmentId});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = true;
  bool _processing = false;
  Map<String, dynamic>? _orderData;

  @override void initState() { super.initState(); _createOrder(); }

  Future<void> _createOrder() async {
    try {
      final result = await ApiService.createPaymentOrder({
        'amount': 500.0,
        'appointment_id': widget.appointmentId,
        'description': 'Consultation Fee',
      });
      if (mounted) setState(() { _orderData = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openRazorpay() async {
    setState(() => _processing = true);
    // In production, this would use razorpay_flutter SDK
    // For now, simulate payment success
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate
      await ApiService.verifyPayment({
        'razorpay_order_id': _orderData?['razorpay_order_id'] ?? '',
        'razorpay_payment_id': 'pay_simulated_${DateTime.now().millisecondsSinceEpoch}',
        'razorpay_signature': 'sig_simulated',
      });
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: HealthCartTheme.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: HealthCartTheme.success, size: 56)),
            const SizedBox(height: 16),
            const Text('Payment Successful!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Your appointment is confirmed.\nThe doctor will join your video call.', textAlign: TextAlign.center,
              style: TextStyle(color: HealthCartTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(context); context.go('/patient'); },
              child: const Text('Go to Home'),
            )),
          ]),
        ));
      }
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 20),
            // Order summary
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: HealthCartTheme.divider),
            ), child: Column(children: [
              const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              _row('Consultation Fee', '₹${((_orderData?['amount'] ?? 50000) / 100).toStringAsFixed(0)}'),
              const Divider(height: 20),
              _row('GST (18%)', '₹0', isSubtle: true),
              _row('Platform Fee', '₹0', isSubtle: true),
              const Divider(height: 20),
              _row('Total', '₹${((_orderData?['amount'] ?? 50000) / 100).toStringAsFixed(0)}', isBold: true),
            ])),
            const SizedBox(height: 24),
            // Payment methods
            Text('Pay via', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _paymentOption(Icons.account_balance_rounded, 'UPI (Google Pay, PhonePe, Paytm)', true),
            _paymentOption(Icons.credit_card_rounded, 'Credit / Debit Card', false),
            _paymentOption(Icons.language_rounded, 'Netbanking', false),
            const Spacer(),
            SizedBox(height: 56, child: ElevatedButton(
              onPressed: _processing ? null : _openRazorpay,
              style: ElevatedButton.styleFrom(backgroundColor: HealthCartTheme.success),
              child: _processing
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    SizedBox(width: 12), Text('Processing...'),
                  ])
                : Text('Pay ₹${((_orderData?['amount'] ?? 50000) / 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 17)),
            )),
          ])),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, bool isSubtle = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, color: isSubtle ? HealthCartTheme.textSecondary : HealthCartTheme.textPrimary)),
      Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: isBold ? HealthCartTheme.primary : HealthCartTheme.textPrimary)),
    ]),
  );

  Widget _paymentOption(IconData icon, String label, bool selected) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: selected ? HealthCartTheme.primary.withOpacity(0.08) : Colors.white,
      borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? HealthCartTheme.primary : HealthCartTheme.divider, width: selected ? 2 : 1)),
    child: Row(children: [
      Icon(icon, color: selected ? HealthCartTheme.primary : HealthCartTheme.textSecondary),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 14))),
      if (selected) const Icon(Icons.check_circle_rounded, color: HealthCartTheme.primary, size: 22),
    ]),
  );
}
