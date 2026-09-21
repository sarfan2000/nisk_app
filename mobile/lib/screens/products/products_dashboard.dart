import 'package:flutter/material.dart';
import 'package:nisk_app/screens/products/add_product_screen.dart';
import 'package:nisk_app/screens/products/find_products_screen.dart';
import 'package:nisk_app/screens/products/my_orders_screen.dart';

class ProductsDashboard extends StatelessWidget {
  const ProductsDashboard({super.key});

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
              'Buy. Sell. Expand.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildOptionCard(context, 'Find Products', Icons.search, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const FindProductsScreen()));
            }),
            _buildOptionCard(context, 'Sell a Product', Icons.storefront, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
            }),
            _buildOptionCard(context, 'Track My Orders', Icons.local_shipping, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProductOrdersScreen()));
            }),
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
