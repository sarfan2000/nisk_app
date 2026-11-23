import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:nisk_app/screens/products/product_details_screen.dart';

class FindProductsScreen extends StatefulWidget {
  const FindProductsScreen({super.key});

  @override
  State<FindProductsScreen> createState() => _FindProductsScreenState();
}

class _FindProductsScreenState extends State<FindProductsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  bool _showVendorFilter = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts({String? search, String? vendor}) async {
    setState(() => _isLoading = true);
    
    try {
      // Build query parameters
      String endpoint = '/products';
      List<String> params = [];
      
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      if (vendor != null && vendor.isNotEmpty) {
        params.add('vendor=${Uri.encodeComponent(vendor)}');
      }
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final data = await _apiService.get(endpoint);
      
      if (mounted) {
        setState(() {
          _filteredProducts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch products: $e'))
        );
      }
    }
  }

  void _performSearch() {
    final searchText = _searchController.text.trim();
    final vendorText = _vendorController.text.trim();
    
    if (searchText.isEmpty && vendorText.isEmpty) {
      // If both are empty, fetch all products
      _fetchProducts();
    } else {
      // Perform filtered search
      _fetchProducts(
        search: searchText.isNotEmpty ? searchText : null,
        vendor: vendorText.isNotEmpty ? vendorText : null,
      );
    }
  }

  void _clearFilters() {
    _searchController.clear();
    _vendorController.clear();
    setState(() {
      _showVendorFilter = false;
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    String resultText = '';
    if (!_isLoading) {
      final searchText = _searchController.text.trim();
      final vendorText = _vendorController.text.trim();
      
      if (searchText.isNotEmpty && vendorText.isNotEmpty) {
        resultText = 'Showing "${searchText}" from "${vendorText}"';
      } else if (searchText.isNotEmpty) {
        resultText = 'Showing results for "${searchText}"';
      } else if (vendorText.isNotEmpty) {
        resultText = 'Showing products from "${vendorText}"';
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIND PRODUCTS'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_searchController.text.isNotEmpty || _vendorController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Main Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products (e.g., Kottu, Bed, Rice)...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _showVendorFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                        color: _showVendorFilter ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showVendorFilter = !_showVendorFilter;
                        });
                      },
                      tooltip: 'Filter by vendor',
                    ),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
              },
              onSubmitted: (value) => _performSearch(),
            ),
          ),
          
          // Vendor Filter (Conditional)
          if (_showVendorFilter)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _vendorController,
                decoration: InputDecoration(
                  hintText: 'Filter by vendor/shop (e.g., Hotel A, Furniture Co.)...',
                  prefixIcon: const Icon(Icons.store, color: Colors.orange),
                  suffixIcon: _vendorController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _vendorController.clear();
                            _performSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.orange.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {}); // Rebuild to show/hide clear button
                },
                onSubmitted: (value) => _performSearch(),
              ),
            ),
          
          // Search Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text('SEARCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          
          // Result Summary
          if (resultText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resultText,
                      style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${_filteredProducts.length} found',
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          
          // Products Grid
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.green)) 
              : _filteredProducts.isEmpty 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty || _vendorController.text.isNotEmpty
                                ? 'Try adjusting your search filters'
                                : 'No products available at the moment',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (_searchController.text.isNotEmpty || _vendorController.text.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Show All Products'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      
                      String? imageUrl;
                      if (product['images'] != null && product['images'].isNotEmpty) {
                        String rawPath = product['images'][0];
                        rawPath = rawPath.replaceAll('\\', '/');
                        String base = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');
                        
                        if (rawPath.startsWith('http')) {
                          imageUrl = rawPath;
                        } else {
                          if (!rawPath.startsWith('/')) {
                            rawPath = '/$rawPath';
                          }
                          imageUrl = '$base$rawPath';
                        }
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
    String shopName = product['shopName'] ?? '';
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.green.withValues(alpha: 0.08),
                            child: const Center(
                              child: Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.green),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.green.withValues(alpha: 0.08),
                          child: const Center(
                            child: Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.green),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (shopName.isNotEmpty) ...[
                     Text(
                       shopName,
                       style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 2),
                   ],
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
