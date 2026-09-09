import 'package:flutter/material.dart';

class EducationCheckoutScreen extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;

  const EducationCheckoutScreen({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    double total = bookingDetails['subtotal'] ?? 0.0;
    double serviceCharge = 100.0;
    double totalBill = total + serviceCharge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER SUMMARY'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(bookingDetails),
            const SizedBox(height: 16),
            _buildBillCard(total, serviceCharge, totalBill),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _processPayment(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              child: const Text('PROCEED TO PAYMENT'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> details) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow('Mode', details['mode'] ?? 'Unknown'),
            _detailRow('Grade', details['grade'] ?? 'Unknown'),
            _detailRow('Subject', details['subject'] ?? 'Unknown'),
            _detailRow('Teacher', details['teacher'] ?? 'Unknown'),
            _detailRow('Classes', details['classes']?.toString() ?? '1'),
            _detailRow('Rate', 'LKR ${details['rate'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(double total, double service, double finalBill) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow('Subtotal', 'LKR $total'),
            _detailRow('Service Charge', 'LKR $service'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL BILL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                Text('LKR $finalBill', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Processing Secure Payment...')
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // close dialog
      Navigator.pushReplacementNamed(context, '/home');
    });
  }
}
