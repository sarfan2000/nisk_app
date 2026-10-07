import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyManpowerHiresScreen extends StatefulWidget {
  const MyManpowerHiresScreen({super.key});

  @override
  State<MyManpowerHiresScreen> createState() => _MyManpowerHiresScreenState();
}

class _MyManpowerHiresScreenState extends State<MyManpowerHiresScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchMyHires();
  }

  Future<void> _fetchMyHires() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/manpower/my-bookings');
      if (response != null && mounted) {
        setState(() {
          _bookings = response;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callWorker(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone dialer')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('MY HIRED TALENT', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF1C40F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMyHires)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF1C40F)))
          : _bookings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final worker = booking['worker'];
                    final workerName = worker != null ? worker['name'] : 'Unknown Worker';
                    final workerPhone = worker != null ? worker['phone'] : '';
                    
                    final status = booking['status'] ?? 'Pending';
                    final paymentStatus = booking['paymentStatus'] ?? 'Pending';
                    final total = booking['total'] ?? 0.0;
                    final category = booking['jobCategory'] ?? 'General Work';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(workerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'Accepted' ? Colors.green.shade100 : const Color(0xFFF1C40F).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: status == 'Accepted' ? Colors.green.shade800 : const Color(0xFFB8950B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Role: $category', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                            const Divider(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Duration: ${booking['duration']} Days', style: const TextStyle(fontSize: 14)),
                                Text('Total: LKR $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Payment: ${paymentStatus == 'Completed' ? 'PAID' : paymentStatus}', 
                                style: TextStyle(color: paymentStatus == 'Completed' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (status == 'Accepted' && workerPhone.isNotEmpty) {
                                    _callWorker(workerPhone);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot call until the Worker accepts the booking!')));
                                  }
                                },
                                icon: const Icon(Icons.phone),
                                label: Text(status == 'Accepted' ? 'CALL WORKER' : 'WAITING FOR APPROVAL'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'Accepted' ? Colors.green : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12)
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No Hires Yet', style: TextStyle(fontSize: 20, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hire a professional to see them here!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

