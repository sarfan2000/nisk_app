import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String currentStatus) async {
    final newStatus = currentStatus == 'Admin_Approved' ? 'Accepted' : 'Admin_Approved';
    try {
      final response = await _apiService.patch('/manpower/bookings/$bookingId/status', {'status': newStatus});
      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
        _fetchWorkerBookings();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  int get _totalEmployers {
    return _bookings.where((b) => b['customer'] != null).map((b) => b['customer']['_id']).toSet().length;
  }

  int get _totalJobs {
    return _bookings.length;
  }

  String get _totalEarnings {
    double earnings = 0;
    for (var b in _bookings) {
      earnings += (b['subtotal'] as num?)?.toDouble() ?? 0.0;
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
        title: const Text('WORKER DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWorkerBookings)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 30, backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
              title: Text('Welcome, Worker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text('Manage your jobs.'),
              trailing: Icon(Icons.edit, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Employers', '$_totalEmployers', Colors.purple),
                _buildStatCard('Jobs', '$_totalJobs', Colors.blue),
                _buildStatCard('Earnings', _totalEarnings, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Upcoming Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _bookings.isEmpty 
                    ? const Padding(padding: EdgeInsets.all(20), child: Text('No jobs assigned yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final b = _bookings[index];
                          final customerName = b['customer'] != null ? b['customer']['name'] : 'Unknown Employer';
                          final jobCategory = b['jobCategory'] ?? 'N/A';
                          final status = b['status'] ?? 'Admin_Approved';
                          final String title = b['orderId'] ?? 'MP-Unknown';
                          final String details = 'Employer: $customerName ($jobCategory)';
                          
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
                   Icon(status == 'Accepted' ? Icons.check_circle : Icons.pending, size: 16, color: status == 'Admin_Approved' ? Colors.orange : Colors.green),
                   const SizedBox(width: 4),
                   Text('Status: $status', style: TextStyle(color: status == 'Admin_Approved' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                ]
              )
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _updateBookingStatus(title, status),
          style: ElevatedButton.styleFrom(
            backgroundColor: status == 'Admin_Approved' ? Colors.green : Colors.grey,
            foregroundColor: Colors.white
          ),
          child: Text(status == 'Admin_Approved' ? 'Approve' : 'Reject'),
        ),
      ),
    );
  }
}
