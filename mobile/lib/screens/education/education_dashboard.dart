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
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('activeRole') ?? prefs.getString('userType') ?? 'Buyer';
      _userName = prefs.getString('userName') ?? 'User';
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
            Text(
              'Welcome, $_userName\nEducation Hub',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Student / Customer specific views
            if (['Student', 'Admin'].contains(_userType) || _userType.isEmpty) ...[
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

            // Fallback for strict mode switching
            if (!['Student', 'Teacher', 'Admin'].contains(_userType) && _userType.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Column(
                  children: [
                    const Icon(Icons.security, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    const Text('Access Restricted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Text('You are currently browsing securely in ${_userType.toUpperCase()} mode.\n\nPlease open the Side Menu and switch your profile to STUDENT or TEACHER mode to access the Education Hub.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade900)),
                  ],
                ),
              ),
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
