import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../education/live_class_screen.dart';
import '../messages/messages_screen.dart';

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
                onBackgroundImageError: _getImageUrl(_profilePic) != null ? (e, s) {} : null,
                child: const Icon(Icons.person, color: Colors.white),
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
                          final studentId = b['student'] != null ? b['student']['_id'] : null;
                          final studentPhone = b['student'] != null ? (b['student']['phone'] ?? '') : '';
                          final grade = b['grade'] != null ? (b['grade'] is Map ? (b['grade']['name'] ?? b['grade']['gradeName'] ?? 'N/A') : b['grade']) : 'N/A';
                          final status = b['status'] ?? 'Pending';
                          final String title = b['bookingId'] ?? 'BK-Unknown';
                          final mode = b['mode'] ?? 'Online';
                          
                          // Extract schedule and subject information from items
                          String scheduleInfo = '';
                          String subjectInfo = '';
                          int totalClasses = 0;
                          
                          if (b['items'] != null && (b['items'] as List).isNotEmpty) {
                            final items = b['items'] as List;
                            List<String> subjects = [];
                            List<String> schedules = [];
                            
                            for (var item in items) {
                              if (item['subject'] != null) {
                                subjects.add(item['subject'].toString());
                              }
                              if (item['schedule'] != null && item['schedule'].toString().isNotEmpty) {
                                schedules.add(item['schedule'].toString());
                              }
                              totalClasses += (item['numberOfClasses'] as num?)?.toInt() ?? 0;
                            }
                            
                            subjectInfo = subjects.isNotEmpty ? subjects.join(', ') : 'General Tuition';
                            scheduleInfo = schedules.isNotEmpty ? schedules.join(' | ') : 'Flexible Schedule';
                          }
                          
                          final String details = 'Student: $studentName ($grade)${studentPhone.isNotEmpty ? '\nPhone: $studentPhone' : ''}';
                          
                          return _buildBookingCard(
                            title, 
                            details, 
                            status, 
                            b['arrangedStartTime'], 
                            b['meetingRoomId'],
                            studentId: studentId,
                            studentName: studentName,
                            studentSchedule: scheduleInfo,
                            subject: subjectInfo,
                            mode: mode,
                            totalClasses: totalClasses,
                          );
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

  Widget _buildBookingCard(
    String title, 
    String details, 
    String status, 
    String? startTime, 
    String? meetingRoomId, 
    {
      String? studentId,
      String studentName = 'Student',
      String studentSchedule = '',
      String subject = '',
      String mode = 'Online',
      int totalClasses = 0,
    }
  ) {
    const textColor = Color(0xFF263247);
    const mutedSurface = Color(0xFFF2F4F8);
    const borderColor = Color(0xFFE1E5EC);
    const actionColor = Color(0xFF315EE7);
    bool isActionable = (status == 'Pending' || status == 'Admin_Approved');
    String displayStatus = status == 'Admin_Approved' ? 'Paid - Action Required' : status;
    String buttonText = isActionable ? 'Accept Class' : (startTime == null ? 'Schedule Class' : 'Complete Class');

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: mutedSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mode == 'Online' ? Icons.videocam : Icons.location_on, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        mode,
                        style: const TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Subject Information
            if (subject.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 18, color: textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (totalClasses > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: mutedSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalClasses ${totalClasses == 1 ? 'class' : 'classes'}',
                        style: const TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            Text(
              details,
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            
            if (studentSchedule.isNotEmpty && studentSchedule != 'Flexible Schedule') ...[
              const SizedBox(height: 12),
              _buildBookingTimeRow(
                icon: Icons.schedule,
                label: 'Requested time',
                value: studentSchedule,
                textColor: textColor,
                backgroundColor: mutedSurface,
              ),
            ],
            
            if (startTime != null) ...[
              const SizedBox(height: 8),
              _buildBookingTimeRow(
                icon: Icons.event_available,
                label: 'Scheduled time',
                value: DateTime.parse(startTime).toLocal().toString().substring(0, 16),
                textColor: textColor,
                backgroundColor: mutedSurface,
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: textColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Status: $displayStatus',
                    style: const TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                if (studentId != null)
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              contactId: studentId,
                              contactName: studentName,
                              contactProfilePic: null,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message_outlined, size: 16),
                      label: const Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: actionColor,
                        side: const BorderSide(color: actionColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (studentId != null) const SizedBox(width: 10),
                
                Expanded(
                  flex: studentId == null ? 1 : 7,
                  child: ElevatedButton.icon(
                    onPressed: startTime != null && status != 'Completed'
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveClassScreen(
                                  channelName: meetingRoomId ?? 'demo',
                                ),
                              ),
                            );
                          }
                        : status == 'Completed'
                            ? null
                            : isActionable
                                ? () => _updateBookingStatus(title, status)
                                : () => _scheduleClass(title),
                    icon: Icon(
                      startTime != null && status != 'Completed'
                          ? Icons.video_call
                          : isActionable
                              ? Icons.check
                              : (startTime == null ? Icons.schedule : Icons.done_all),
                      size: 18,
                    ),
                    label: Text(
                      startTime != null && status != 'Completed' ? 'Join Live' : buttonText,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: mutedSurface,
                      disabledForegroundColor: textColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTimeRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
