import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ManpowerCheckoutScreen extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;

  const ManpowerCheckoutScreen({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    double total = bookingDetails['subtotal'] ?? 0.0;
    double serviceCharge = bookingDetails['serviceCharge'] ?? 0.0;
    double totalBill = bookingDetails['total'] ?? total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER SUMMARY'),
        backgroundColor: const Color(0xFFF1C40F),
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
            _detailRow('Service', details['category'] ?? 'Unknown'),
            _detailRow('Location', details['location'] ?? 'Unknown'),
            _detailRow('Professional', details['professional'] ?? 'Unknown'),
            _detailRow('Days', details['days']?.toString() ?? '1'),
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
                const Text('TOTAL BILL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF1C40F))),
                Text('LKR $finalBill', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF1C40F))),
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

  void _processPayment(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFF1C40F)),
            SizedBox(height: 16),
            Text('Redirecting to PayHere Secure Gateway...')
          ],
        ),
      ),
    );

    try {
      final ApiService api = ApiService();
      final response = await api.post('/manpower/book', {
        'workerId': bookingDetails['workerId'],
        'jobCategory': bookingDetails['category'],
        'duration': bookingDetails['days'],
        'rate': bookingDetails['rate'],
        'serviceCharge': bookingDetails['serviceCharge'],
        'total': bookingDetails['total']
      });

      if (context.mounted) Navigator.pop(context); // Close loader

      if (response != null && response['paymentUrl'] != null) {
         final String paymentUrl = '${ApiService.baseUrl.replaceAll('/api', '')}${response['paymentUrl']}';
         final Uri url = Uri.parse(paymentUrl);
         
         if (await canLaunchUrl(url)) {
           await launchUrl(url, mode: LaunchMode.inAppWebView);
         } else {
           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch payment portal')));
         }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }
}

