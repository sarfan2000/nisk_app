import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nisk_app/screens/products/product_details_screen.dart';

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
                        product: product,
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
  final Map<String, dynamic> product;
  final String? imageUrl;

  const ProductCard({super.key, required this.product, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    String name = product['name'] ?? 'Product';
    String price = 'LKR ${product['price']}';
    String stock = product['stock'] > 0 ? '${product['stock']} In Stock' : 'Out of Stock';
    String rating = (product['rating'] ?? 0.0).toString();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: product,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'product_image_${product['_id']}',
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
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                   const SizedBox(height: 4),
                   Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 4),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(stock, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                       Row(
                         children: [
                           const Icon(Icons.star, color: Colors.amber, size: 12),
                           Text(rating, style: const TextStyle(fontSize: 10)),
                         ],
                       )
                     ],
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
