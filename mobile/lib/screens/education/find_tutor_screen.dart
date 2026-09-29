import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/tutor_details_screen.dart';
import 'package:nisk_app/services/api_service.dart';

class FindTutorScreen extends StatefulWidget {
  const FindTutorScreen({super.key});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  final TextEditingController _searchController = TextEditingController();


  List<dynamic> _teachers = [];
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchFilteredTeachers(); // Load initial teachers
  }



  Future<void> _fetchFilteredTeachers() async {
    setState(() => _isLoading = true);
    try {
      String query = '';
      if (_searchController.text.trim().isNotEmpty) {
        query = '?search=${Uri.encodeComponent(_searchController.text.trim())}';
      }

      
      final data = await _apiService.get('/teacher$query');
      if (mounted) {
        setState(() {
          _teachers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load teachers: $e')));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Find a Tutor'),
        backgroundColor: Colors.redAccent,
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
                hintText: 'Search by subject, location, mode or name...',
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
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
                    _fetchFilteredTeachers();
                  },
                ),
              ),
              onSubmitted: (_) => _fetchFilteredTeachers(),
              textInputAction: TextInputAction.search,
            ),
          ),
          
          // Teacher List Section
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
              : _teachers.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No tutors found matching these filters', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        return _buildTeacherCard(_teachers[index]);
                      },
                    ),
          )
        ],
      ),
    );
  }



  Widget _buildTeacherCard(Map<String, dynamic> t) {
    final user = t['user'] ?? {};
    final name = user['name'] ?? 'Professional Tutor';
    final rate = t['hourlyRate'] ?? 1000;
    
    String? imageUrl;
    if (t['profilePicture'] != null && t['profilePicture'].toString().isNotEmpty) {
      String rawPath = t['profilePicture'].toString();
      rawPath = rawPath.replaceAll('\\', '/');
      String base = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');
      if (!rawPath.startsWith('/')) rawPath = '/$rawPath';
      imageUrl = '$base$rawPath';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to full details page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TutorDetailsScreen(
                teacher: t,
                imageUrl: imageUrl,
              )
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'tutor_${t['_id']}',
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.red.shade50,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null ? const Icon(Icons.person, size: 35, color: Colors.redAccent) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1)),
                        if (t['isVerified'] == true) const Icon(Icons.verified, color: Colors.blue, size: 18)
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Exp: ${t['experience'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text('LKR $rate / hr', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${t['rating'] ?? 5.0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
