import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/education_dashboard.dart';
import 'package:nisk_app/screens/manpower/manpower_dashboard.dart';
import 'package:nisk_app/screens/products/products_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFB11218)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFFB11218)),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const Drawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Image.asset(
                  'assets/images/Nisk.jpeg',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'NISK Manpower Consultant (PVT) Ltd.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                   Text('CONNECT', style: TextStyle(color: Color(0xFF9E1B1E), fontWeight: FontWeight.bold, fontSize: 13)),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 6.0),
                     child: Text('•', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                   ),
                   Text('EMPOWER', style: TextStyle(color: Color(0xFFE5B914), fontWeight: FontWeight.bold, fontSize: 13)),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 6.0),
                     child: Text('•', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                   ),
                   Text('GROW', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'One Platform.\nEndless Opportunities.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildLargeSectorButton(
                context,
                title: 'EDUCATION ',
                subtitle: 'Learn. Teach. Grow',
                color: const Color(0xFFBA1A1A),
                icon: Icons.school,
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const EducationDashboard()));
                }
              ),
              const SizedBox(height: 14),
              _buildLargeSectorButton(
                context,
                title: 'MANPOWER ',
                subtitle: 'Find Jobs. Hire Talent',
                color: const Color(0xFFF1C40F),
                icon: Icons.groups,
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const ManpowerDashboard()));
                }
              ),
              const SizedBox(height: 14),
              _buildLargeSectorButton(
                context,
                title: 'PRODUCTION & SALES ',
                subtitle: 'Buy. Sell. Expand',
                color: const Color(0xFF278E33),
                icon: Icons.shopping_cart,
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsDashboard()));
                }
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFB11218),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildLargeSectorButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
