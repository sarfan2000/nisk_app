import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MyProductOrdersScreen extends StatefulWidget {
  const MyProductOrdersScreen({super.key});

  @override
  State<MyProductOrdersScreen> createState() => _MyProductOrdersScreenState();
}

class _MyProductOrdersScreenState extends State<MyProductOrdersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/products/my-orders');
      if (response != null && mounted) {
        setState(() {
          _orders = response;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'order placed':
        return Colors.blue;
      case 'payment confirmed':
        return Colors.purple;
      case 'processing':
        return Colors.orange;
      case 'dispatched':
      case 'out for delivery':
        return Colors.amber;
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('MY ORDERS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyOrders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchMyOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final product = order['product'];
                      final productName = product != null ? product['name'] : 'Unknown Product';
                      final orderId = order['orderId'] ?? order['_id'].toString().substring(0, 8);
                      final orderStatus = order['orderStatus'] ?? 'Order Placed';
                      final paymentStatus = order['paymentStatus'] ?? 'Pending';
                      final total = order['total'] ?? 0.0;
                      final date = order['createdAt'] != null ? DateTime.parse(order['createdAt']).toLocal().toString().split('.')[0] : 'Unknown Date';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order: $orderId',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: paymentStatus == 'Paid' ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      paymentStatus == 'Paid' ? 'PAID' : paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: paymentStatus == 'Paid' ? Colors.green.shade800 : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.shopping_bag, color: Colors.green, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        Text('Quantity: ${order['quantity']}   |   Total: LKR $total', style: TextStyle(color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Order Tracking Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.local_shipping, size: 16, color: _getStatusColor(orderStatus)),
                                        const SizedBox(width: 8),
                                        Text(
                                          orderStatus.toUpperCase(),
                                          style: TextStyle(fontWeight: FontWeight.w900, color: _getStatusColor(orderStatus)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('Placed on: $date', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No Orders Found', style: TextStyle(fontSize: 20, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You havent placed any product orders yet.', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
