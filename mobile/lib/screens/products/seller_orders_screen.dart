import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:intl/intl.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  final List<String> _validStatuses = [
    'Payment Confirmed',
    'Processing',
    'Packed',
    'Dispatched',
    'Out for Delivery',
    'Delivered',
    'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSellerOrders();
  }

  Future<void> _fetchSellerOrders() async {
    try {
      final response = await _apiService.get('/products/seller-orders');
      if (mounted) {
        setState(() {
          _orders = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _apiService.patch(
          '/products/orders/$orderId/status', {'orderStatus': newStatus});
      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: Colors.green));
        _fetchSellerOrders(); // Refresh table
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'), backgroundColor: Colors.red));
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> order) {
    if (order['paymentStatus'] != 'Paid' &&
        order['paymentStatus'] != 'Confirmed') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot process un-paid orders.')));
      return;
    }

    String currentStatus = order['orderStatus'] ?? 'Order Placed';
    if (!_validStatuses.contains(currentStatus))
      currentStatus = _validStatuses.first;

    showDialog(
        context: context,
        builder: (context) {
          String selectedStatus = currentStatus;
          return StatefulBuilder(builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Update Order Status'),
              content: DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Order Progress'),
                items: _validStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setStateSB(() => selectedStatus = val);
                },
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (selectedStatus != currentStatus) {
                      _updateOrderStatus(order['orderId'], selectedStatus);
                    }
                  },
                  child: const Text('Update Status'),
                )
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Manage Sales & Orders'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green))
            : _orders.isEmpty
                ? const Center(
                    child: Text('You have no sales or orders yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final productMatch = order['product'] ?? {};
                      final productName =
                          productMatch['name'] ?? 'Unknown Product';
                      final qty = order['quantity'] ?? 1;
                      final total = order['total'] ?? 0;
                      final orderStatus =
                          order['orderStatus'] ?? 'Order Placed';
                      final payStatus = order['paymentStatus'] ?? 'Pending';
                      final orderId = order['orderId'] ?? 'N/A';
                      final date = order['createdAt'] != null
                          ? DateFormat.yMMMd()
                              .format(DateTime.parse(order['createdAt']))
                          : 'Unknown Date';

                      bool isPaid =
                          payStatus == 'Paid' || payStatus == 'Confirmed';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Order #$orderId',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(date,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12)),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(productName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Quantity: $qty  |  Total Paid: LKR $total',
                                  style:
                                      TextStyle(color: Colors.grey.shade800)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: isPaid
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text('Payment: $payStatus',
                                        style: TextStyle(
                                            color: isPaid
                                                ? Colors.green.shade800
                                                : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.blue.shade200)),
                                    child: Text('Status: $orderStatus',
                                        style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isPaid
                                      ? () => _showStatusUpdateDialog(order)
                                      : null,
                                  icon: const Icon(Icons.edit_note),
                                  label: Text(isPaid
                                      ? 'Update Progress Status'
                                      : 'Waiting for Payment'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: isPaid
                                          ? Colors.green.shade700
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ));
  }
}
