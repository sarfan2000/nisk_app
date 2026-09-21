import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/checkout_screen.dart';
import 'package:nisk_app/services/api_service.dart';

class FindTutorScreen extends StatefulWidget {
  const FindTutorScreen({super.key});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  int _currentStep = 0;
  
  String? _selectedMode;
  String? _selectedLocation;
  String? _selectedGrade;
  String? _selectedSubject;
  Map<String, dynamic>? _selectedTeacher;
  int _numberOfClasses = 1;

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
      setState(() {
        _teachers = data;
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Find Tutor'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedMode == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill it: Select Learning Mode')));
            return;
          }
          if (_currentStep == 1 && (_selectedLocation == null || _selectedLocation!.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Location from available teachers')));
            return;
          }
          if (_currentStep == 2 && _selectedGrade == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill it: Select a Grade')));
            return;
          }
          if (_currentStep == 3 && _selectedSubject == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill it: Select a Subject')));
            return;
          }
          if (_currentStep == 3) {
             // Fetch teachers before moving to step 4
             _fetchFilteredTeachers();
          }
          if (_currentStep == 4 && _selectedTeacher == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill it: Select a Teacher!')));
            return;
          }
          if (_currentStep < 5) {
            setState(() => _currentStep += 1);
          } else {
            // Checkout logical
            _showCheckoutDialog();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('Learning Mode'),
            content: Row(
              children: [
                Expanded(child: RadioListTile<String>(
                  title: const Text('Online'),
                  value: 'Online',
                  groupValue: _selectedMode,
                  onChanged: (val) {
                    setState(() {
                      _selectedMode = val;
                      _selectedLocation = null;
                      _selectedGrade = null;
                      _selectedSubject = null;
                    });
                    _fetchFilters();
                  },
                  activeColor: Colors.redAccent,
                )),
                Expanded(child: RadioListTile<String>(
                  title: const Text('Offline'),
                  value: 'Offline',
                  groupValue: _selectedMode,
                  onChanged: (val) {
                    setState(() {
                      _selectedMode = val;
                      _selectedLocation = null;
                      _selectedGrade = null;
                      _selectedSubject = null;
                    });
                    _fetchFilters();
                  },
                  activeColor: Colors.redAccent,
                )),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Location'),
            content: DropdownButtonFormField<String>(
              value: _selectedLocation,
              items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedLocation = val;
                  _selectedGrade = null;
                  _selectedSubject = null;
                });
                _fetchFilters();
              },
              decoration: const InputDecoration(labelText: 'Select City/Area', border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Select Grade'),
            content: DropdownButtonFormField<String>(
              value: _selectedGrade,
              items: _grades.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGrade = val;
                  _selectedSubject = null;
                });
                _fetchFilters();
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Select Subject'),
            content: DropdownButtonFormField<String>(
              value: _selectedSubject,
              items: _subjects.map((subj) => DropdownMenuItem(value: subj, child: Text(subj))).toList(),
              onChanged: (val) {
                setState(() => _selectedSubject = val);
                _fetchFilters();
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Select Teacher'),
            content: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _teachers.isEmpty 
                    ? const Text('No teachers found.')
                    : Column(
                        children: _teachers.map((t) {
                          final user = t['user'] ?? {};
                          final name = user['name'] ?? 'Unknown Teacher';
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
                            color: (_selectedTeacher != null && _selectedTeacher!['_id'] == t['_id']) ? Colors.red.shade50 : Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                                child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                              ),
                              title: Row(
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (t['isVerified'] == true) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: Colors.blue, size: 16)
                                  ]
                                ],
                              ),
                              subtitle: Text('Exp: ${t['experience']} | Rate: LKR $rate/hr'),
                              trailing: Text('⭐ ${t['rating'] ?? 0}'),
                              onTap: () => setState(() => _selectedTeacher = t),
                            ),
                          );
                        }).toList(),
                      ),
            isActive: _currentStep >= 4,
          ),
          Step(
            title: const Text('Class Details'),
            content:Row(
              children: [
                const Text('Number of Classes: '),
                IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if(_numberOfClasses>1) _numberOfClasses--;})),
                Text('$_numberOfClasses', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _numberOfClasses++)),
              ],
            ),
            isActive: _currentStep >= 5,
          )
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    double rate = (_selectedTeacher != null && _selectedTeacher!['hourlyRate'] != null) 
       ? double.tryParse(_selectedTeacher!['hourlyRate'].toString()) ?? 1500.0 
       : 1500.0;
    String teacherName = _selectedTeacher != null && _selectedTeacher!['user'] != null 
       ? (_selectedTeacher!['user']['name'] ?? 'Unknown') 
       : 'None selected';
       
    double subtotal = rate * _numberOfClasses;
    double serviceCharge = subtotal * 0.10; // 10% fee
    double grandTotal = subtotal + serviceCharge;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ORDER SUMMARY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode: $_selectedMode'),
            Text('Grade: $_selectedGrade'),
            Text('Subject: $_selectedSubject'),
            Text('Teacher: $teacherName'),
            const Divider(),
            Text('Classes: $_numberOfClasses'),
            Text('Rate: LKR $rate'),
            Text('Subtotal: LKR $subtotal'),
            Text('Service Charge (10%): LKR $serviceCharge'),
            const Divider(),
            Text('Total Amount: LKR $grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => EducationCheckoutScreen(
                 bookingDetails: {
                   'mode': _selectedMode,
                   'grade': _selectedGrade,
                   'subject': _selectedSubject,
                   'teacher': teacherName,
                   'teacherId': _selectedTeacher?['user']?['_id'] ?? _selectedTeacher?['_id'],
                   'classes': _numberOfClasses,
                   'rate': rate,
                   'subtotal': subtotal,
                   'serviceCharge': serviceCharge,
                   'total': grandTotal
                 }
               )));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('PROCEED TO PAYMENT'),
          )
        ],
      ),
    );
  }
}
