import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../education/live_class_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _userName = 'Teacher';
  String? _profilePic;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTeacherBookings();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Teacher';
      _profilePic = prefs.getString('profilePic');
      if (_profilePic != null && _profilePic!.isEmpty) _profilePic = null;
    });
  }

  String? _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    String baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    return '$baseUrl/${path.replaceAll('\\', '/')}';
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
    final newStatus = (currentStatus == 'Pending' || currentStatus == 'Admin_Approved') ? 'Teacher_Approved' : 'Completed';
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

  Future<void> _scheduleClass(String bookingId) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return;
    
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    
    try {
      final response = await _apiService.patch('/education/bookings/$bookingId/schedule', {
        'arrangedStartTime': start.toIso8601String(),
        'arrangedEndTime': start.add(const Duration(hours: 1)).toIso8601String()
      });
      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class Scheduled Successfully!')));
        _fetchTeacherBookings();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 30, 
                backgroundColor: Colors.redAccent, 
                backgroundImage: _getImageUrl(_profilePic) != null ? NetworkImage(_getImageUrl(_profilePic)!) : null,
                child: _getImageUrl(_profilePic) == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              title: Text('Welcome, $_userName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('Manage your schedule.'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () async {
                  // Usually, this should switch to the Profile tab. We can push the ProfileScreen on top just for editing.
                  await Navigator.pushNamed(context, '/profile'); 
                  _loadUserData(); // Reload image and name after returning block
                },
              ),
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
                          
                          return _buildBookingCard(title, details, status, b['arrangedStartTime'], b['meetingRoomId']);
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

  Widget _buildBookingCard(String title, String details, String status, String? startTime, String? meetingRoomId) {
    bool isActionable = (status == 'Pending' || status == 'Admin_Approved');
    String displayStatus = status == 'Admin_Approved' ? 'Paid - Action Required' : status;
    String buttonText = isActionable ? 'Accept Class' : (startTime == null ? 'Schedule Class' : 'Complete Class');
    Color buttonColor = isActionable ? Colors.green : (startTime == null ? Colors.purple : (status == 'Completed' ? Colors.grey : Colors.blue));

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
               if (startTime != null) ...[
                 const SizedBox(height: 4),
                 Text('Scheduled: ${DateTime.parse(startTime).toLocal().toString().substring(0, 16)}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
               ],
               const SizedBox(height: 4),
               Row(
                 children: [
                    Icon(isActionable ? Icons.pending : Icons.check_circle, size: 16, color: isActionable ? Colors.orange : Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Status: $displayStatus', style: TextStyle(color: isActionable ? Colors.orange : Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                 ]
               )
             ],
           ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (startTime != null && status != 'Completed')
              ElevatedButton(
                 onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => 
                      LiveClassScreen(channelName: meetingRoomId ?? 'demo')
                    ));
                 },
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(100, 32)),
                 child: const Text('Join Live'),
              ),
            if (startTime == null || status == 'Completed')
              ElevatedButton(
                 onPressed: status == 'Completed' ? null : (isActionable ? () => _updateBookingStatus(title, status) : () => _scheduleClass(title)),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: buttonColor,
                   foregroundColor: Colors.white,
                 ),
                 child: Text(buttonText),
              ),
          ],
        ),
      ),
    );
  }
}

