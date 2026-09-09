import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/find_tutor_screen.dart';

class EducationDashboard extends StatelessWidget {
  const EducationDashboard({super.key});

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
              'Learn. Teach. Grow.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(context, 'Find Tutors', Icons.person_search, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FindTutorScreen()));
            }),
            _buildOptionCard(context, 'Find Courses', Icons.menu_book, () {}),
            _buildOptionCard(context, 'Online Classes', Icons.laptop_chromebook, () {}),
            _buildOptionCard(context, 'Educational Resources', Icons.library_books, () {}),
            _buildOptionCard(context, 'Institutions', Icons.account_balance, () {}),
            _buildOptionCard(context, 'Exams & Preparation', Icons.assignment, () {}),
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
