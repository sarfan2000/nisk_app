import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

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
                hintText: 'What service or product are you looking for?',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onSubmitted: (value) {
                // Trigger global search logic
              },
            ),
          ),
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
                _buildFilterChip('Mathematics Teacher', Colors.redAccent),
                const SizedBox(width: 8),
                _buildFilterChip('Cleaner', Colors.blue),
                const SizedBox(width: 8),
                _buildFilterChip('Construction Worker', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('Products', Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Search across all NISK services', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
