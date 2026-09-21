import 'package:flutter/material.dart';
import 'package:nisk_app/screens/manpower/find_employees_screen.dart';
import 'package:nisk_app/screens/manpower/post_job_screen.dart';
import 'package:nisk_app/screens/manpower/my_hires_screen.dart';

class ManpowerDashboard extends StatelessWidget {
  const ManpowerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NISK MANPOWER'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Hire Talent.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(context, 'Post a Job', Icons.post_add, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen()));
            }),
            _buildOptionCard(context, 'Find Workers', Icons.people_alt, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FindEmployeesScreen()));
            }),
            _buildOptionCard(context, 'My Hired Talent', Icons.work, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyManpowerHiresScreen()));
            }),
            _buildOptionCard(context, 'Recruitment Services', Icons.handshake, () {}),
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
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
