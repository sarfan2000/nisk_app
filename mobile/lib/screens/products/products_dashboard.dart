import 'package:flutter/material.dart';
import 'package:nisk_app/screens/products/add_product_screen.dart';
import 'package:nisk_app/screens/products/find_products_screen.dart';
import 'package:nisk_app/screens/products/my_orders_screen.dart';
import 'package:nisk_app/screens/products/seller_orders_screen.dart';
import 'package:nisk_app/screens/products/seller_dashboard.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ProductsDashboard extends StatefulWidget {
  const ProductsDashboard({super.key});

  @override
  State<ProductsDashboard> createState() => _ProductsDashboardState();
}

class _ProductsDashboardState extends State<ProductsDashboard> {
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('activeRole') ?? prefs.getString('userType') ?? 'Buyer';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRODUCTION & SALES', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Marketplace Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Customer / Buyer views
            if (['Buyer', 'Admin'].contains(_userType) || _userType.isEmpty) ...[
              _buildOptionCard(context, 'Find Products', Icons.search, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const FindProductsScreen()));
              }),
              _buildOptionCard(context, 'Track My Orders', Icons.local_shipping, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProductOrdersScreen()));
              }),
            ],

            // Seller views
            if (['Seller', 'Admin'].contains(_userType)) ...[
              _buildOptionCard(context, 'Seller Dashboard', Icons.dashboard, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerDashboard()));
              }),
              _buildOptionCard(context, 'Sell a Product', Icons.storefront, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
              }),
              _buildOptionCard(context, 'Manage Sales & Orders', Icons.assignment, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerOrdersScreen()));
              }),
            ],

            // Fallback for strict mode switching
            if (!['Buyer', 'Seller', 'Admin'].contains(_userType) && _userType.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Column(
                  children: [
                    const Icon(Icons.security, color: Colors.green, size: 40),
                    const SizedBox(height: 12),
                    const Text('Access Restricted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                    const SizedBox(height: 8),
                    Text('You are currently browsing securely in ${_userType.toUpperCase()} mode.\n\nPlease open the Side Menu and switch your profile to BUYER or SELLER mode to access the Products Hub.', textAlign: TextAlign.center, style: TextStyle(color: Colors.green.shade900)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
