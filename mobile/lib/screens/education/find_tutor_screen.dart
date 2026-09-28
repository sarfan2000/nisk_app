import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/tutor_details_screen.dart';
import 'package:nisk_app/services/api_service.dart';

class FindTutorScreen extends StatefulWidget {
  const FindTutorScreen({super.key});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  String? _selectedMode;
  String? _selectedLocation;
  String? _selectedGrade;
  String? _selectedSubject;

  List<String> _locations = [];
  List<String> _grades = [];
  List<String> _subjects = [];
  List<dynamic> _teachers = [];
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchFilters();
    _fetchFilteredTeachers(); // Load initial teachers
  }

  Future<void> _fetchFilters() async {
    try {
      String query = '';
      if (_selectedMode != null) query += '?mode=${Uri.encodeComponent(_selectedMode!)}';
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) query += '${query.isEmpty ? '?' : '&'}location=${Uri.encodeComponent(_selectedLocation!)}';
      if (_selectedGrade != null) query += '${query.isEmpty ? '?' : '&'}grade=${Uri.encodeComponent(_selectedGrade!)}';
      
      final data = await _apiService.get('/teacher/filters$query');
      if (mounted) {
        setState(() {
          _locations = List<String>.from(data['locations'] ?? []);
          _grades = List<String>.from(data['grades'] ?? []);
          _subjects = List<String>.from(data['subjects'] ?? []);
          
          if (_selectedLocation != null && !_locations.contains(_selectedLocation)) _selectedLocation = null;
          if (_selectedGrade != null && !_grades.contains(_selectedGrade)) _selectedGrade = null;
          if (_selectedSubject != null && !_subjects.contains(_selectedSubject)) _selectedSubject = null;
        });
      }
    } catch (e) {
      print('Error fetching filters: $e');
    }
  }

  Future<void> _fetchFilteredTeachers() async {
    setState(() => _isLoading = true);
    try {
      String query = '';
      if (_selectedSubject != null) query += '?subject=${Uri.encodeComponent(_selectedSubject!)}';
      if (_selectedGrade != null) query += '${query.isEmpty ? '?' : '&'}grade=${Uri.encodeComponent(_selectedGrade!)}';
      if (_selectedMode != null) query += '${query.isEmpty ? '?' : '&'}mode=${Uri.encodeComponent(_selectedMode!)}';
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) query += '${query.isEmpty ? '?' : '&'}location=${Uri.encodeComponent(_selectedLocation!)}';
      
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

  void _onFilterChanged() {
    _fetchFilters();
    _fetchFilteredTeachers();
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
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown('Mode', _selectedMode, ['Online', 'Offline'], (val) {
                        setState(() { _selectedMode = val; _selectedLocation = null; });
                        _onFilterChanged();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown('Grade', _selectedGrade, _grades, (val) {
                        setState(() => _selectedGrade = val);
                        _onFilterChanged();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown('Location', _selectedLocation, _locations, (val) {
                        setState(() => _selectedLocation = val);
                        _onFilterChanged();
                      }, isEnabled: _selectedMode == 'Offline'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown('Subject', _selectedSubject, _subjects, (val) {
                        setState(() => _selectedSubject = val);
                        _onFilterChanged();
                      }),
                    ),
                  ],
                ),
              ],
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

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged, {bool isEnabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.grey.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
          value: items.contains(value) ? value : null,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: isEnabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.redAccent),
        ),
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
                selectedMode: _selectedMode,
                selectedGrade: _selectedGrade,
                selectedSubject: _selectedSubject,
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
