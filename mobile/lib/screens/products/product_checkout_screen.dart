import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    image: widget.imageUrl != null 
                        ? DecorationImage(image: NetworkImage(widget.imageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: widget.imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Redirecting to PayHere Secure Gateway...')
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
         final Uri url = Uri.parse(paymentUrl);
         
         if (await canLaunchUrl(url)) {
           await launchUrl(url, mode: LaunchMode.inAppWebView);
         } else {
           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch payment portal')));
         }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    }
  }
}
