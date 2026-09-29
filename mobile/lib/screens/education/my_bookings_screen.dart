import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../education/live_class_screen.dart';
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('userType') ?? 'Student';

    try {
      String endpoint = '/education/my-bookings'; // Default for Student
      if (_userType == 'Teacher') {
        endpoint = '/teacher/bookings/me';
      } else if (_userType == 'Admin') {
        endpoint = '/admin/bookings/pending';
      }

      final response = await _apiService.get(endpoint);
      if (response != null && mounted) {
        setState(() {
          _bookings = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'teacher_approved':
      case 'completed':
      case 'accepted':
        return Colors.green;
      case 'admin_approved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      String endpoint = '';
      if (_userType == 'Admin') {
        endpoint = '/admin/bookings/$bookingId/approve'; // The backend sets status to Admin_Approved
      } else if (_userType == 'Teacher') {
        endpoint = '/teacher/booking/$bookingId/status';
      }

      final body = {'status': newStatus};
      final response = await _apiService.patch(endpoint, body);
      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated successfully!')));
        _fetchBookings(); // Refresh the list
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
        title: const Text('My Class Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookings,
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
                      Icon(Icons.menu_book, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No bookings found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                    final String bookingStatus = booking['status'] ?? 'Pending';
                    final double total = (booking['totalBill'] ?? 0).toDouble();
                    final List items = booking['items'] ?? [];
                    final String subject = items.isNotEmpty ? items[0]['subject']?.toString() ?? 'N/A' : 'Unknown Class';
                    final String teacherName = (items.isNotEmpty && items[0]['teacher'] != null && items[0]['teacher'] is Map) 
                         ? items[0]['teacher']['name'] ?? 'Assigned Teacher' 
                         : 'Assigned Teacher';

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
                                  booking['bookingId'] ?? 'Unknown ID',
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
                                Text(teacherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.menu_book, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(subject, style: const TextStyle(fontSize: 15)),
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
                                    bookingStatus == 'Accepted' ? Icons.check_circle : (bookingStatus == 'Pending' ? Icons.access_time : Icons.cancel),
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

                            if (booking['arrangedStartTime'] != null) ...[
                               const SizedBox(height: 12),
                               Container(
                                 width: double.infinity,
                                 padding: const EdgeInsets.symmetric(vertical: 8),
                                 child: Text(
                                   'Scheduled: ${DateTime.parse(booking['arrangedStartTime']).toLocal().toString().substring(0, 16)}', 
                                   textAlign: TextAlign.center,
                                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 15)
                                 ),
                               ),
                               if (bookingStatus != 'Completed')
                                  ElevatedButton.icon(
                                    onPressed: () {
                                       Navigator.push(context, MaterialPageRoute(
                                         builder: (context) => LiveClassScreen(channelName: booking['meetingRoomId'] ?? 'demo')
                                       ));
                                    },
                                    icon: const Icon(Icons.video_camera_front, color: Colors.white),
                                    label: const Text('JOIN LIVE CLASS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                       backgroundColor: Colors.redAccent,
                                       minimumSize: const Size.fromHeight(45),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                    ),
                                  )
                            ],
                            
                            // Approval Actions based on Role
                            if (_userType == 'Admin' && bookingStatus == 'Pending') ...[
                               const SizedBox(height: 12),
                               ElevatedButton(
                                 onPressed: () => _updateStatus(booking['_id'], 'Admin_Approved'),
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size.fromHeight(40)),
                                 child: const Text('Verify & Approve Payment', style: TextStyle(color: Colors.white)),
                               ),
                            ],
                            if (_userType == 'Teacher' && bookingStatus == 'Admin_Approved') ...[
                               const SizedBox(height: 12),
                               Row(
                                 children: [
                                   Expanded(
                                     child: ElevatedButton(
                                       onPressed: () => _updateStatus(booking['_id'], 'Teacher_Approved'),
                                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                       child: const Text('Accept', style: TextStyle(color: Colors.white)),
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   Expanded(
                                     child: ElevatedButton(
                                       onPressed: () => _updateStatus(booking['_id'], 'Rejected'),
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
