import 'package:flutter/material.dart';

class EmployerDashboard extends StatelessWidget {
  const EmployerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMPLOYER DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 30, backgroundColor: Colors.orange, child: Icon(Icons.business, color: Colors.white)),
              title: Text('BuildMax LK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text('ID: NISK-EMP-045'),
              trailing: Icon(Icons.settings, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Active Jobs', '3', Colors.blue),
                _buildStatCard('Total Applicants', '12', Colors.purple),
                _buildStatCard('Hired', '5', Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Job Postings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildJobCard('Construction Supervisor', 'Trincomalee', '3 Applicants', 'Active'),
            _buildJobCard('Heavy Vehicle Driver', 'Colombo', '9 Applicants', 'Active'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('POST NEW JOB'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildJobCard(String title, String location, String applicants, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location),
            Text(applicants, style: const TextStyle(color: Colors.orange)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)
          ),
          child: const Text('REVIEW'),
        ),
      ),
    );
  }
}
