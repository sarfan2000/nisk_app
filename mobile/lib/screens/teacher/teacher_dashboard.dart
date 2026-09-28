import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherBookings();
  }

  Future<void> _fetchTeacherBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/education/teacher-bookings');
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

  Future<void> _updateBookingStatus(String bookingId, String currentStatus) async {
    final newStatus = currentStatus == 'Pending' ? 'Accepted' : 'Pending';
    try {
      final response = await _apiService.patch('/education/bookings/$bookingId/status', {'status': newStatus});
      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
        _fetchTeacherBookings();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  int get _totalStudents {
    return _bookings.where((b) => b['student'] != null).map((b) => b['student']['_id']).toSet().length;
  }

  int get _totalClasses {
    int count = 0;
    for (var b in _bookings) {
      if (b['items'] != null) {
        for (var item in b['items']) {
          count += (item['numberOfClasses'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return count;
  }

  String get _totalEarnings {
    double earnings = 0;
    for (var b in _bookings) {
      if (b['items'] != null) {
        for (var item in b['items']) {
          earnings += (item['subtotal'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    if (earnings >= 1000) {
      return 'LKR ${(earnings / 1000).toStringAsFixed(1)}K';
    }
    return 'LKR ${earnings.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEACHER DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTeacherBookings)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 30, backgroundColor: Colors.redAccent, child: Icon(Icons.person, color: Colors.white)),
              title: Text('Welcome, Teacher', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text('Manage your schedule.'),
              trailing: Icon(Icons.edit, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Students', '$_totalStudents', Colors.purple),
                _buildStatCard('Classes', '$_totalClasses', Colors.blue),
                _buildStatCard('Earnings', _totalEarnings, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Upcoming Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _bookings.isEmpty 
                    ? const Padding(padding: EdgeInsets.all(20), child: Text('No student bookings assigned yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final b = _bookings[index];
                          final studentName = b['student'] != null ? b['student']['name'] : 'Unknown Student';
                          final grade = b['grade'] ?? 'N/A';
                          final status = b['status'] ?? 'Pending';
                          final String title = b['bookingId'] ?? 'BK-Unknown';
                          final String details = 'Student: $studentName ($grade)';
                          
                          return _buildBookingCard(title, details, status);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(String title, String details, String status) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(details, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                   Icon(status == 'Accepted' ? Icons.check_circle : Icons.pending, size: 16, color: status == 'Pending' ? Colors.orange : Colors.green),
                   const SizedBox(width: 4),
                   Expanded(
                     child: Text('Status: $status', style: TextStyle(color: status == 'Pending' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                   ),
                ]
              )
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _updateBookingStatus(title, status),
          style: ElevatedButton.styleFrom(
            backgroundColor: status == 'Pending' ? Colors.green : Colors.grey,
            foregroundColor: Colors.white
          ),
          child: Text(status == 'Pending' ? 'Approve' : 'Reject'),
        ),
      ),
    );
  }
}
