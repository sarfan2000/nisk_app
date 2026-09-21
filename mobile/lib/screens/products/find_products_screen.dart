import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FindProductsScreen extends StatefulWidget {
  const FindProductsScreen({super.key});

  @override
  State<FindProductsScreen> createState() => _FindProductsScreenState();
}

class _FindProductsScreenState extends State<FindProductsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await _apiService.get('/products');
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch products: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIND PRODUCTS'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _products.isEmpty 
                ? const Center(child: Text('No products available.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      // Use product defaults for missing fields if any
                      
                      String? imageUrl;
                      if (product['images'] != null && product['images'].isNotEmpty) {
                        String rawPath = product['images'][0];
                        rawPath = rawPath.replaceAll('\\', '/');
                        // ApiService.baseUrl is "http://localhost:5001/api", we need to remove "/api"
                        String base = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');
                        
                        if (!rawPath.startsWith('/')) {
                          rawPath = '/$rawPath';
                        }
                        imageUrl = '$base$rawPath';
                        print('Product image URL generated: $imageUrl');
                      }

                      return ProductCard(
                        name: product['name'] ?? 'Product', 
                        price: 'LKR ${product['price']}', 
                        stock: product['stock'] > 0 ? '${product['stock']} In Stock' : 'Out of Stock', 
                        rating: (product['rating'] ?? 0.0).toString(),
                        productId: product['_id'],
                        imageUrl: imageUrl,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} // Removed FAB since it goes to the dashboard menu

class ProductCard extends StatelessWidget {
  final String name, price, stock, rating;
  final String? productId;
  final String? imageUrl;

  const ProductCard({super.key, required this.name, required this.price, required this.stock, required this.rating, this.productId, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: imageUrl != null 
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null 
                  ? const Icon(Icons.image, size: 50, color: Colors.green)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stock, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('⭐ $rating', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => _showCheckout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('BUY NOW', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ORDER SUMMARY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: $name'),
            const Text('Quantity: 1'),
            Text('Unit Price: $price'),
            const Divider(),
            const Text('Delivery: LKR 300'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (productId == null) return;
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text('Generating Secure Payment...')
                    ],
                  ),
                ),
              );

              try {
                final response = await ApiService().post('/products/order', {
                  'productId': productId,
                  'quantity': 1,
                  'deliveryLocation': 'Colombo, Sri Lanka',
                  'deliveryFee': 300
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('PAY NOW'),
          )
        ],
      ),
    );
  }
}
