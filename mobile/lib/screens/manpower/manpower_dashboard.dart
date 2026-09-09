import 'package:flutter/material.dart';
import 'package:nisk_app/screens/manpower/find_jobs_screen.dart';
import 'package:nisk_app/screens/manpower/employer_dashboard.dart';

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
              'Find Jobs. Hire Talent.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('JOB SEEKER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            _buildOptionCard(context, 'Find Jobs', Icons.search, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FindJobsScreen()));
            }),
            _buildOptionCard(context, 'CV / Resume Upload', Icons.upload_file, () {}),
            _buildOptionCard(context, 'My Applications', Icons.work_history, () {}),
            
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('EMPLOYER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            _buildOptionCard(context, 'Employer Dashboard', Icons.business_center, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployerDashboard()));
            }),
            _buildOptionCard(context, 'Post a Job', Icons.post_add, () {}),
            _buildOptionCard(context, 'Find Employees', Icons.people_alt, () {}),
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
