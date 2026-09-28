import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _availableOrders = [];
  List<dynamic> _myDeliveries = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final availableRes = await _apiService.get('/delivery/available-orders');
      final deliveriesRes = await _apiService.get('/delivery/my-deliveries');
      
      if (mounted) {
        setState(() {
          _availableOrders = availableRes ?? [];
          _myDeliveries = deliveriesRes ?? [];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await _apiService.patch('/delivery/accept/$orderId', {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted successfully!'), backgroundColor: Colors.green));
      _fetchDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _completeDelivery(String orderId) async {
    try {
      await _apiService.patch('/delivery/complete/$orderId', {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery marked as Complete!'), backgroundColor: Colors.green));
      _fetchDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DELIVERY HUB', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDashboardData)],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'AVAILABLE ORDERS'),
              Tab(text: 'MY DELIVERIES'),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : TabBarView(
              children: [
                _buildAvailableOrdersView(),
                _buildMyDeliveriesView(),
              ],
            ),
      ),
    );
  }

  Widget _buildAvailableOrdersView() {
    if (_availableOrders.isEmpty) {
      return const Center(child: Text('No orders are currently waiting for delivery.', style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        final pName = order['product'] != null ? order['product']['name'] : 'Item';
        final cLocation = order['deliveryLocation'] ?? 'Unknown location';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.local_shipping, color: Colors.white)),
            title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Dropoff: $cLocation'),
            trailing: ElevatedButton(
              onPressed: () => _acceptOrder(order['orderId']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text('Accept'),
            ),
          ),
        );
      }
    );
  }

  Widget _buildMyDeliveriesView() {
    if (_myDeliveries.isEmpty) {
      return const Center(child: Text('You have no active deliveries.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myDeliveries.length,
      itemBuilder: (context, index) {
        final order = _myDeliveries[index];
        final pName = order['product'] != null ? order['product']['name'] : 'Item';
        final cLocation = order['deliveryLocation'] ?? 'Unknown location';
        final cPhone = order['customer'] != null ? order['customer']['phone'] : 'No Phone';
        final status = order['orderStatus'] ?? 'Unknown';
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text('Order ID: ${order['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Text(status, style: TextStyle(color: status == 'Delivered' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const Divider(),
                Text('Item: $pName', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Dropoff: $cLocation', style: TextStyle(color: Colors.grey.shade700)),
                Text('Customer Phone: $cPhone', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging / Call opened (Requires Plugin)')));
                        },
                        icon: const Icon(Icons.message, color: Colors.teal),
                        label: const Text('Message', style: TextStyle(color: Colors.teal)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: status == 'Delivered' ? null : () => _completeDelivery(order['orderId']),
                        icon: const Icon(Icons.check),
                        label: Text(status == 'Delivered' ? 'Completed' : 'Complete'),
                        style: ElevatedButton.styleFrom(backgroundColor: status == 'Delivered' ? Colors.grey : Colors.green, foregroundColor: Colors.white),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
