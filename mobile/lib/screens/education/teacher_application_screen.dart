import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nisk_app/services/api_service.dart';

class TeacherApplicationScreen extends StatefulWidget {
  const TeacherApplicationScreen({super.key});

  @override
  State<TeacherApplicationScreen> createState() => _TeacherApplicationScreenState();
}

class _TeacherApplicationScreenState extends State<TeacherApplicationScreen> {
  final _experienceController = TextEditingController();
  final _descController = TextEditingController();
  final _daysController = TextEditingController();
  final _timeController = TextEditingController();
  final _rateController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedMode = 'Online';
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();
  
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  XFile? _profilePicture;
  Uint8List? _webImageBytes;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profilePicture = image;
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _profilePicture = image;
        });
      }
    }
  }

  Future<void> _submitApplication() async {
    if (_experienceController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _daysController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _gradeController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final Map<String, String> fields = {
        'experience': _experienceController.text,
        'shortDescription': _descController.text,
        'availableDays': _daysController.text,
        'availableTime': _timeController.text,
        'hourlyRate': _rateController.text.isNotEmpty ? _rateController.text : '0',
        'subjects': jsonEncode([_subjectController.text]),
        'grades': jsonEncode([_gradeController.text]),
        'modes': jsonEncode([_selectedMode]),
        'location': _locationController.text,
      };

      // In real scenario, userId comes from JWT payload logic, but here we can rely on backend reading it from x-auth-token
      // Wait, backend route is /api/teacher/profile/:userId. The mobile UI doesn't know userId unless fetched via Auth Provider.
      // But let's check other endpoints. For simplicity, we can pass a dummy userId if auth is not fully hooked in state, or use a method in api_service.
      // We will check auth logic.
      
      // We'll require user to login and get token. Assuming token has user ID, or we fetch it.
      // Actually backend expects userId in url params. Let's see how manpower handles it?
      // For now, I'll update backend to read from req.user.id if :userId is not explicitly needed.
      
      const String dummyUserId = 'me'; // We will adjust backend to accept 'me' or read from token
      
      if (_profilePicture != null) {
        await _apiService.postMultipart('/teacher/profile/$dummyUserId', fields, [_profilePicture!]);
      } else {
        await _apiService.post('/teacher/profile/$dummyUserId', fields);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully sent your information, Admin will review this.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSubmitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teach with Us'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  ),
                  child: _profilePicture == null
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : ClipOval(
                          child: kIsWeb && _webImageBytes != null
                              ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                              : !kIsWeb 
                                  ? Image.file(File(_profilePicture!.path), fit: BoxFit.cover)
                                  : const Icon(Icons.broken_image),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Profile Picture', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 24),
            TextField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience (e.g. 8 Years)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Short Description', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 16),
            TextField(controller: _daysController, decoration: const InputDecoration(labelText: 'Available Days (e.g. Mon, Wed, Fri)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'Available Time (e.g. 4 PM - 6 PM)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject (e.g. Mathematics)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _gradeController, decoration: const InputDecoration(labelText: 'Grade (e.g. Grade 10)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'City/Location', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: const InputDecoration(labelText: 'Teaching Mode', border: OutlineInputBorder()),
              items: ['Online', 'Offline', 'Both'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _selectedMode = val ?? 'Online'),
            ),
            const SizedBox(height: 16),
            TextField(controller: _rateController, decoration: const InputDecoration(labelText: 'Hourly Rate (e.g. 1500)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
