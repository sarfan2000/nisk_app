import 'package:flutter/material.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEACHER DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 30, backgroundColor: Colors.redAccent, child: Icon(Icons.person, color: Colors.white)),
              title: Text('Welcome, Teacher A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text('ID: NISK-T-001'),
              trailing: Icon(Icons.edit, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Students', '45', Colors.purple),
                _buildStatCard('Classes', '12', Colors.blue),
                _buildStatCard('Earnings', 'LKR 85K', Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Upcoming Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildBookingCard('Booking BK-1002', 'Student: John Doe (Grade 5 Math)', 'Tomorrow, 4:00 PM', 'Pending'),
            _buildBookingCard('Booking BK-1004', 'Student: Alice (O/L Science)', 'Friday, 6:00 PM', 'Accepted'),
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
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(String title, String details, String time, String status) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details),
            Text(time, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: status == 'Pending' ? Colors.orange : Colors.green,
            foregroundColor: Colors.white
          ),
          child: Text(status),
        ),
      ),
    );
  }
}
