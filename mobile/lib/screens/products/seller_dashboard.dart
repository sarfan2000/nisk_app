import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'seller_orders_screen.dart';
import 'add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _sellerOrders = [];
  String _userName = 'Seller';
  String? _profilePic;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSellerOrders();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Seller';
      _profilePic = prefs.getString('profilePic');
      if (_profilePic != null && _profilePic!.isEmpty) _profilePic = null;
    });
  }

  String? _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    String baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    return '$baseUrl/${path.replaceAll('\\', '/')}';
  }

  Future<void> _fetchSellerOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/products/seller-orders');
      if (response != null && mounted) {
        setState(() {
          _sellerOrders = response;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalPendingOrders {
    return _sellerOrders.where((o) => o['orderStatus'] == 'Pending' || o['orderStatus'] == 'Packed').length;
  }

  int get _totalCompletedOrders {
    return _sellerOrders.where((o) => o['orderStatus'] == 'Delivered').length;
  }

  String get _totalEarnings {
    double earnings = 0;
    for (var o in _sellerOrders) {
      if (o['orderStatus'] == 'Delivered') {
        earnings += (o['subtotal'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (earnings >= 1000) {
      return 'LKR ${(earnings / 1000).toStringAsFixed(1)}K';
    }
    return 'LKR ${earnings.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELLER DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF57224), // Temu/Alibaba Orange
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSellerOrders)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 30, 
                backgroundColor: const Color(0xFFF57224), 
                backgroundImage: _getImageUrl(_profilePic) != null ? NetworkImage(_getImageUrl(_profilePic)!) : null,
                child: _getImageUrl(_profilePic) == null ? const Icon(Icons.storefront, color: Colors.white) : null,
              ),
              title: Text('Welcome, $_userName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('Manage your store.'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/profile'); 
                  _loadUserData(); 
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Pending', '$_totalPendingOrders', Colors.blue),
                _buildStatCard('Completed', '$_totalCompletedOrders', Colors.green),
                _buildStatCard('Earnings', _totalEarnings, Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_shopping_cart, color: Color(0xFFF57224)),
                title: const Text('Add New Product'),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                },
              )
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Color(0xFFF57224)),
                title: const Text('Manage Sales & Orders'),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerOrdersScreen()));
                },
              )
            ),
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
}
