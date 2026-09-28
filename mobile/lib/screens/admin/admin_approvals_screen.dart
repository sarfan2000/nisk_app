import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _manpowerBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingBookings();
  }

  Future<void> _fetchPendingBookings() async {
    setState(() => _isLoading = true);
    try {
      final mpResponse = await _apiService.get('/admin/manpower-bookings/pending');
      
      if (mounted) {
        setState(() {
          _manpowerBookings = mpResponse ?? [];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load pending approvals: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveManpowerBooking(String id) async {
    try {
      await _apiService.patch('/admin/manpower-bookings/$id/approve', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment Approved! Worker Notified.'),
          backgroundColor: Colors.green,
        ));
        _fetchPendingBookings();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals (Admin)'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _manpowerBookings.isEmpty
              ? const Center(child: Text('No pending manpower bookings.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _manpowerBookings.length,
                  itemBuilder: (context, index) {
                    final b = _manpowerBookings[index];
                    final customerName = b['customer'] != null ? b['customer']['name'] : 'Unknown Customer';
                    final workerName = b['worker'] != null ? b['worker']['name'] : 'Unknown Worker';
                    final rate = b['rate'] ?? 0;
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.handyman, color: Colors.white)),
                        title: Text('Booking ID: ${b['orderId']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Employer: $customerName'),
                            Text('Worker: $workerName'),
                            Text('Service: ${b['jobCategory']} (LKR $rate)'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () => _approveManpowerBooking(b['_id']),
                          child: const Text('APPROVE PAYMENT'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
