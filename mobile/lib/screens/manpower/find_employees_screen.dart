import 'package:flutter/material.dart';
import 'package:nisk_app/screens/manpower/worker_details_screen.dart';
import 'package:nisk_app/services/api_service.dart';

class FindEmployeesScreen extends StatefulWidget {
  const FindEmployeesScreen({super.key});

  @override
  State<FindEmployeesScreen> createState() => _FindEmployeesScreenState();
}

class _FindEmployeesScreenState extends State<FindEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();


  List<dynamic> _employees = [];
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchFilteredEmployees();
  }



  Future<void> _fetchFilteredEmployees() async {
    setState(() => _isLoading = true);
    try {
      String query = '';
      if (_searchController.text.trim().isNotEmpty) {
        query = '?search=${Uri.encodeComponent(_searchController.text.trim())}';
      }

      
      final data = await _apiService.get('/manpower/jobs$query');
      if (mounted) {
        setState(() {
          _employees = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load workers: $e')));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Hire Professionals'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by category, location, title or name...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchFilteredEmployees();
                  },
                ),
              ),
              onSubmitted: (_) => _fetchFilteredEmployees(),
              textInputAction: TextInputAction.search,
            ),
          ),
          
          // Worker List Section
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : _employees.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No professionals found matching these filters', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _employees.length,
                      itemBuilder: (context, index) {
                        return _buildWorkerCard(_employees[index]);
                      },
                    ),
          )
        ],
      ),
    );
  }



  Widget _buildWorkerCard(Map<String, dynamic> e) {
    final name = e['company'] ?? 'Independent Professional';
    final title = e['title'] ?? 'Worker';
    final rate = e['salary'] ?? 'Negotiable';
    final isAvailable = e['isAvailable'] ?? true;
    final locationName = e['location'] != null ? e['location']['city'] ?? 'Unknown' : 'Unknown';
    
    String? imageUrl;
    if (e['jobPicture'] != null && e['jobPicture'].toString().isNotEmpty) {
      String rawPath = e['jobPicture'].toString();
      rawPath = rawPath.replaceAll('\\', '/');
      String base = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');
      if (!rawPath.startsWith('/')) rawPath = '/$rawPath';
      imageUrl = '$base$rawPath';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isAvailable ? Colors.transparent : Colors.grey.shade300)
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isAvailable ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerDetailsScreen(
                worker: e,
                imageUrl: imageUrl,
                selectedCategory: e['category'] ?? 'Category',
                selectedLocation: locationName,
              )
            ),
          );
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'worker_${e['_id']}',
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                    image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                  ),
                  child: imageUrl == null ? const Icon(Icons.work, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isAvailable ? Colors.black : Colors.grey), maxLines: 1)),
                        if (e['isVerified'] == true) const Icon(Icons.verified, color: Colors.blue, size: 18)
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text(rate, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.red,
                      shape: BoxShape.circle
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (locationName.isNotEmpty) Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(locationName, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
