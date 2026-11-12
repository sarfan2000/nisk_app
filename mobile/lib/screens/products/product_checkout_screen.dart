import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nisk_app/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final double price;
  final String? imageUrl;
  final double deliveryFee = 300.0;

  const ProductCheckoutScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  @override
  State<ProductCheckoutScreen> createState() => _ProductCheckoutScreenState();
}

class _ProductCheckoutScreenState extends State<ProductCheckoutScreen> {
  String _deliveryAddress = 'Colombo, Sri Lanka'; // Default

  void _changeAddress() {
    TextEditingController controller = TextEditingController(text: _deliveryAddress);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Enter full address'
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _deliveryAddress = controller.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = widget.price * widget.quantity;
    double totalBill = subtotal + widget.deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SECURE CHECKOUT'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProductSummaryCard(widget.product, widget.quantity, widget.price),
            const SizedBox(height: 16),
            _buildDeliveryCard(),
            const SizedBox(height: 16),
            _buildBillCard(subtotal, widget.deliveryFee, totalBill),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _processPayment(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              child: const Text('PAY NOW'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummaryCard(Map<String, dynamic> product, int quantity, double price) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.imageUrl!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.green.withOpacity(0.1),
                              child: const Icon(Icons.shopping_bag_outlined, color: Colors.green, size: 28),
                            ),
                          )
                        : Container(
                            color: Colors.green.withOpacity(0.1),
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.green, size: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Quantity: $quantity', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Text('LKR ${price * quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shipping Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_deliveryAddress, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                TextButton(onPressed: _changeAddress, child: const Text('Change', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(double subtotal, double delivery, double finalBill) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow('Item(s) Subtotal', 'LKR $subtotal'),
            _detailRow('Delivery Fee', 'LKR $delivery'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL PAYMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('LKR $finalBill', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Creating your order...')
          ],
        ),
      ),
    );

    try {
      final ApiService api = ApiService();
      final response = await api.post('/products/order', {
        'productId': widget.product['_id'],
        'quantity': widget.quantity,
        'deliveryLocation': _deliveryAddress,
        'deliveryFee': widget.deliveryFee,
      });

      if (context.mounted) Navigator.pop(context); // Close loader

      if (response != null && response['paymentUrl'] != null) {
        final String paymentUrl = '${ApiService.baseUrl.replaceAll('/api', '')}${response['paymentUrl']}';
        final String orderId = response['orderId'] ?? '';
        final Uri url = Uri.parse(paymentUrl);

        // Save orderId to prefs so we can check status when user returns
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_product_order_id', orderId);

        if (await canLaunchUrl(url)) {
          // Launch PayHere in external browser — most reliable on Flutter Web
          await launchUrl(url, mode: LaunchMode.externalApplication);

          // After user returns from browser, show a "Check Payment Status" screen
          // instead of blindly navigating to Home
          if (context.mounted) {
            _showPaymentReturnDialog(context, orderId);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch payment portal. Please try again.')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create order. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e')),
        );
      }
    }
  }

  void _showPaymentReturnDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.payment, color: Colors.green),
              SizedBox(width: 8),
              Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_browser, size: 48, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'PayHere payment page was opened in your browser.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Order ID: $orderId',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'After completing payment in the browser, tap "Done" below to check your order status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Go back to product list — payment not confirmed yet
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Navigate to My Orders so user can see payment status
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Done — View My Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
