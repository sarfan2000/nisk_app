import 'package:flutter/material.dart';
import 'admin_approvals_screen.dart';
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN CONTROL CENTER', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Super Admin Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Users', '12.4K', Colors.blue),
                _buildStatCard('Active Jobs', '342', Colors.orange),
                _buildStatCard('Pending Approvals', '45', Colors.redAccent),
                _buildStatCard('Revenue (LKR)', '4.5M', Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Management Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in, color: Colors.green),
              title: const Text('Manpower Payment Approvals'),
              subtitle: const Text('Approve payments to notify workers'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminApprovalsScreen()));
              },
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.shopping_cart_checkout),
              title: const Text('Product Approvals'),
              subtitle: const Text('Approve products for the marketplace'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Audit & Reports'),
              subtitle: const Text('View system logs and financial targets'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
