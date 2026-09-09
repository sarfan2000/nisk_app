import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/education_dashboard.dart';
import 'package:nisk_app/screens/manpower/manpower_dashboard.dart';
import 'package:nisk_app/screens/cleaning/cleaning_dashboard.dart';
import 'package:nisk_app/screens/products/products_dashboard.dart';
import 'package:nisk_app/screens/admin/admin_dashboard.dart';
import 'package:nisk_app/screens/messages/messages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NISK App', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.message), 
            onPressed: () { 
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen())); 
            }
          ),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What do you need?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCategoryCard(context, 'Education', 'Learn, Teach, Grow.', Colors.redAccent, Icons.school),
              _buildCategoryCard(context, 'Manpower', 'Find Jobs, Hire Talent.', Colors.orange, Icons.work),
              _buildCategoryCard(context, 'Production & Sales', 'Buy, Sell, Expand.', Colors.green, Icons.shopping_cart),
              _buildCategoryCard(context, 'Cleaning Services', 'Professional cleaning solutions.', Colors.blue, Icons.cleaning_services),
              const SizedBox(height: 24),
              _buildCategoryCard(context, 'Admin Console', 'Manage platform activities.', Colors.black87, Icons.admin_panel_settings),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          if (title == 'Education') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EducationDashboard()));
          } else if (title == 'Manpower') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManpowerDashboard()));
          } else if (title == 'Cleaning Services') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CleaningDashboard()));
          } else if (title == 'Production & Sales') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsDashboard()));
          } else if (title == 'Admin Console') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
          }
        },
      ),
    );
  }
}
