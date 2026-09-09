import 'package:flutter/material.dart';

class CleaningDashboard extends StatelessWidget {
  const CleaningDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NISK CLEANING'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Professional Cleaning Solutions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            _buildServiceCard(context, 'Home Cleaning', Icons.home),
            _buildServiceCard(context, 'Office Cleaning', Icons.business),
            _buildServiceCard(context, 'Construction Site Cleaning', Icons.construction),
            _buildServiceCard(context, 'Dengue Prevention', Icons.medical_services_outlined),
            _buildServiceCard(context, 'Event Cleaning', Icons.event),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showBookingSheet(context, title);
        },
      ),
    );
  }

  void _showBookingSheet(BuildContext context, String service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Book $service', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(labelText: 'Date & Time', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(labelText: 'Property Details', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleaning Request Submitted!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('SUBMIT REQUEST'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
