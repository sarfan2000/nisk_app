import 'package:flutter/material.dart';
import 'package:nisk_app/screens/manpower/find_employees_screen.dart';
import 'package:nisk_app/screens/manpower/post_job_screen.dart';
import 'package:nisk_app/screens/manpower/my_hires_screen.dart';
import 'package:nisk_app/screens/manpower/my_job_bookings_screen.dart';
import 'package:nisk_app/screens/manpower/worker_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManpowerDashboard extends StatefulWidget {
  const ManpowerDashboard({super.key});

  @override
  State<ManpowerDashboard> createState() => _ManpowerDashboardState();
}

class _ManpowerDashboardState extends State<ManpowerDashboard> {
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
        title: const Text('NISK MANPOWER'),
        backgroundColor: const Color(0xFFF1C40F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Welcome, $_userName\nManpower Hub',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF1C40F)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Employer / Customer views
            if (['Employer', 'Admin'].contains(_userType) || _userType.isEmpty) ...[
              _buildOptionCard(context, 'Find Workers', Icons.people_alt, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FindEmployeesScreen()));
              }),
              _buildOptionCard(context, 'My Hired Talent (Track Status)', Icons.work, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyManpowerHiresScreen()));
              }),
            ],

            // Worker views
            if (['Worker', 'Admin'].contains(_userType)) ...[
              _buildOptionCard(context, 'Worker Dashboard', Icons.dashboard, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerDashboard()));
              }),
              _buildOptionCard(context, 'Review Job Bookings', Icons.assignment_turned_in, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const MyJobBookingsScreen()));
              }),
              _buildOptionCard(context, 'Post a Job / Service', Icons.post_add, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen()));
              }),
            ],

            // Fallback for strict mode switching
            if (!['Employer', 'Worker', 'Admin'].contains(_userType) && _userType.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1C40F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1C40F).withValues(alpha: 0.3))),
                child: Column(
                  children: [
                    const Icon(Icons.security, color: Color(0xFFF1C40F), size: 40),
                    const SizedBox(height: 12),
                    const Text('Access Restricted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFF1C40F))),
                    const SizedBox(height: 8),
                    Text('You are currently browsing securely in ${_userType.toUpperCase()} mode.\n\nPlease open the Side Menu and switch your profile to EMPLOYER or WORKER mode to access the Manpower Hub.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
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
        leading: Icon(icon, color: const Color(0xFFF1C40F)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

