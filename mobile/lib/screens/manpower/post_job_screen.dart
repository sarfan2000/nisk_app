import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nisk_app/services/api_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  
  XFile? _jobPicture;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();
  
  String _selectedCategory = 'Hair Cutting';
  String _selectedJobType = 'Full Time';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Hair Cutting', 'Mason', 'Carpenter', 'Doctor',
    'Electrician', 'Plumber', 'cleaner', 'Facial'
  ];

  final List<String> _jobTypes = [
    'Full Time', 'Part Time', 'Temporary', 'Contract', 'Daily', 'Freelance'
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _jobPicture = image;
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _jobPicture = image;
        });
      }
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_jobPicture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo for the job'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'title': _titleController.text,
        'company': _companyController.text,
        'category': _selectedCategory,
        'jobType': _selectedJobType,
        'location': jsonEncode({'city': _locationController.text}),
        'salary': _salaryController.text,
        'description': _descriptionController.text,
        'nicNumber': _nicController.text,
        'phoneNumber': _phoneController.text,
        'isActive': 'true',
        'isVerified': 'true', // Auto-verify for testing purposes
      };

      await ApiService().postMultipart('/manpower/jobs', payload, [_jobPicture!]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile successfully posted! You are now visible to Employers.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post job: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: Colors.orange,
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
                    child: _jobPicture == null
                        ? const Center(child: Text('Photo *\nTap', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent)))
                        : ClipOval(
                            child: kIsWeb && _webImageBytes != null
                                ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                : !kIsWeb 
                                    ? Image.file(File(_jobPicture!.path), fit: BoxFit.cover)
                                    : const Icon(Icons.broken_image),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicController,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'NIC Number ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'NIC Number is required';
                  if (value.trim().length != 12) return 'NIC must be exactly 12 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Phone Number ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Phone Number is required';
                  if (!RegExp(r'^\d+$').hasMatch(value.trim())) return 'Phone number must contain only numbers';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Job Title ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Job Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Company / Employer Name ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Company/Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Service / Category ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? 'Hair Cutting'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Job Type ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                items: _jobTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedJobType = val ?? 'Full Time'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'City / Location ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(label: const Text.rich(TextSpan(text: 'Salary / Rate (e.g. LKR 2000) ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))])), border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Salary/Rate is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder()),
                maxLines: 3,
                // optional field
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJob,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('POST JOB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
