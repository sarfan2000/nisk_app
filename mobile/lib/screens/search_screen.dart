import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _hasSearched = false;

  List<dynamic> _teachers = [];
  List<dynamic> _jobs = [];
  List<dynamic> _products = [];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await _apiService.get('/search?query=${Uri.encodeComponent(query)}');
      if (mounted) {
        setState(() {
          _teachers = response['teachers'] ?? [];
          _jobs = response['jobs'] ?? [];
          _products = response['products'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GLOBAL SEARCH', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tutors, jobs, or products...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onSubmitted: _performSearch,
            ),
          ),
          if (!_hasSearched) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Suggested Categories', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Mathematics', Colors.blue, 'Math'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cleaner', Colors.orange, 'Cleaner'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Oil', Colors.green, 'Oil'),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.manage_search, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Search across all NISK services', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          ] else if (_isLoading) ...[
            const Expanded(child: Center(child: CircularProgressIndicator()))
          ] else ...[
            Expanded(
              child: _buildSearchResults(),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    int totalResults = _teachers.length + _jobs.length + _products.length;

    if (totalResults == 0) {
      return const Center(child: Text('No results found for your search.', style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_teachers.isNotEmpty) ...[
          const Text('Education Tutors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          const Divider(),
          ..._teachers.map((t) => _buildResultTile(t['name'] ?? 'Tutor', t['location'], Icons.school, Colors.red)),
          const SizedBox(height: 16),
        ],
        if (_jobs.isNotEmpty) ...[
          const Text('Manpower Listings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
          const Divider(),
          ..._jobs.map((j) => _buildResultTile(j['title'] ?? j['category'] ?? 'Worker', j['location'] ?? j['company'], Icons.groups, Colors.orange)),
          const SizedBox(height: 16),
        ],
        if (_products.isNotEmpty) ...[
          const Text('Marketplace Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const Divider(),
          ..._products.map((p) => _buildResultTile(p['name'] ?? p['category'] ?? 'Product', 'LKR ${p['price']}', Icons.shopping_cart, Colors.green)),
        ]
      ],
    );
  }

  Widget _buildResultTile(String title, dynamic subtitle, IconData icon, Color color) {
    String subStr = '';
    if (subtitle != null) {
      if (subtitle is String) {
        subStr = subtitle;
      } else if (subtitle is Map) {
        subStr = subtitle['city'] ?? 'Location N/A';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subStr),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          // Navigating straight to the relevant modules can be built here.
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please navigate to the exact hub to view this item!')));
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color, String query) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      onPressed: () => _performSearch(query),
    );
  }
}
