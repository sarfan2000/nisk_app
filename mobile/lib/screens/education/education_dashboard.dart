import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/find_tutor_screen.dart';
import 'package:nisk_app/screens/education/teacher_application_screen.dart';
import 'package:nisk_app/screens/education/my_bookings_screen.dart';
import 'package:nisk_app/screens/teacher/teacher_dashboard.dart';

import 'package:shared_preferences/shared_preferences.dart';

class EducationDashboard extends StatefulWidget {
  const EducationDashboard({super.key});

  @override
  State<EducationDashboard> createState() => _EducationDashboardState();
}

class _EducationDashboardState extends State<EducationDashboard> {
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('userType') ?? 'Buyer';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NISK EDUCATION'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Education Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            
            // Student / Customer specific views
            if (['Student', 'Buyer', 'Employer', 'Admin'].contains(_userType) || _userType.isEmpty) ...[
              _buildOptionCard(context, 'Find Tutors', Icons.person_search, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FindTutorScreen()));
              }),
              _buildOptionCard(context, 'My Bookings (Status)', Icons.history_edu, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
              }),
            ],

            // Teacher specific views
            if (['Teacher', 'Admin'].contains(_userType)) ...[
              _buildOptionCard(context, 'Teacher Dashboard Data', Icons.dashboard, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherDashboard()));
              }),
              _buildOptionCard(context, 'My Student Bookings', Icons.event_available, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen())); // Ensure this screen handles teacher queries
              }),
              _buildOptionCard(context, 'Teach with Us (Application)', Icons.school, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherApplicationScreen()));
              }),
            ],


            _buildOptionCard(context, 'Educational Resources', Icons.library_books, () {}),
            if (['Admin'].contains(_userType))
              _buildOptionCard(context, 'Admin: Verify Teachers', Icons.admin_panel_settings, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
