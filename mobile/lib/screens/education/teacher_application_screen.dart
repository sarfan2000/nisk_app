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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) {
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              TextFormField(
                controller: _experienceController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Experience (e.g. 8 Years) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Experience is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Short Description ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()), 
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _daysController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Available Days (e.g. Mon, Wed, Fri) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Available Days req.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Available Time (e.g. 4 PM - 6 PM) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Available Time req.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Subject (e.g. Mathematics) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Grade (e.g. Grade 10) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Grade is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'City/Location ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'City/Location is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMode,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Teaching Mode ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                items: ['Online', 'Offline', 'Both'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _selectedMode = val ?? 'Online'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController, 
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Hourly Rate (e.g. 1500) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()), 
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Hourly Rate is required' : null,
              ),
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
      ),
    );
  }
}
