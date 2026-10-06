import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MyJobBookingsScreen extends StatefulWidget {
  const MyJobBookingsScreen({super.key});

  @override
  State<MyJobBookingsScreen> createState() => _MyJobBookingsScreenState();
}

class _MyJobBookingsScreenState extends State<MyJobBookingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkerBookings();
  }

  Future<void> _fetchWorkerBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/manpower/worker-bookings');
      if (response != null && mounted) {
        setState(() {
          _bookings = response;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'admin_approved':
        return Colors.blue;
      case 'pending':
        return const Color(0xFFF1C40F);
      case 'failed':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      final body = {'status': newStatus};
      final response = await _apiService.patch('/manpower/bookings/$bookingId/status', body);
      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully!')));
        _fetchWorkerBookings(); // Refresh the list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Job Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF1C40F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkerBookings,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No jobs assigned yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final dateString = booking['createdAt'] ?? '';
                    final DateTime parsedDate = dateString.isNotEmpty ? DateTime.tryParse(dateString) ?? DateTime.now() : DateTime.now();
                    final formattedDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
                    
                    final String paymentStatus = booking['paymentStatus'] ?? 'Pending';
                    final String bookingStatus = booking['status'] ?? 'Admin_Approved';
                    final double total = (booking['total'] ?? 0).toDouble();
                    final String jobCategory = booking['jobCategory'] ?? 'N/A';
                    final String customerName = booking['customer'] != null ? booking['customer']['name'] : 'Unknown Employer';
                    final String orderId = booking['orderId'] ?? 'MP-Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  orderId,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(paymentStatus).withAlpha(30),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    paymentStatus == 'Completed' ? 'PAID' : paymentStatus.toUpperCase(),
                                    style: TextStyle(color: _getStatusColor(paymentStatus), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                )
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.work_outline, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(jobCategory, style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                Text(
                                  'Rs. ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Booking Approval Status Badge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    bookingStatus == 'Accepted' ? Icons.check_circle : (bookingStatus == 'Admin_Approved' ? Icons.access_time : Icons.cancel),
                                    color: _getStatusColor(bookingStatus),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Status: $bookingStatus', 
                                    style: TextStyle(fontWeight: FontWeight.w600, color: _getStatusColor(bookingStatus)),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Approval Actions based on Role
                            if (bookingStatus == 'Admin_Approved') ...[
                               const SizedBox(height: 12),
                               Row(
                                 children: [
                                   Expanded(
                                     child: ElevatedButton(
                                       onPressed: () => _updateStatus(orderId, 'Accepted'),
                                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                       child: const Text('Accept', style: TextStyle(color: Colors.white)),
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   Expanded(
                                     child: ElevatedButton(
                                       onPressed: () => _updateStatus(orderId, 'Rejected'),
                                       style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                       child: const Text('Reject', style: TextStyle(color: Colors.white)),
                                     ),
                                   ),
                                 ]
                               )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

