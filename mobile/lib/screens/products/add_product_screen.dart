import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nisk_app/services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _deliveryAvailable = true;
  bool _isSubmitting = false;

  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      // On web we want to eagerly read bytes to display it
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, String> fields = {
        'name': _nameController.text,
        'category': _categoryController.text.isEmpty ? 'General' : _categoryController.text,
        'description': _descController.text,
        'price': (double.tryParse(_priceController.text) ?? 0).toString(),
        'stock': (int.tryParse(_stockController.text) ?? 1).toString(),
        'deliveryAvailable': _deliveryAvailable.toString(),
      };

      if (_selectedImages.isNotEmpty) {
        await _apiService.postMultipart('/products', fields, _selectedImages);
      } else {
        await _apiService.post('/products', fields);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully sent your information, Admin will review this.')));
        Navigator.pop(context, true); // Return true to refresh
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
        title: const Text('SELL YOUR PRODUCT'),
        backgroundColor: Colors.green,
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
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  ),
                  child: _selectedImages.isEmpty 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to select Product Images', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final file = _selectedImages[index];
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8.0),
                                width: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    // For web we use network, for native we use File
                                    image: kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path)) as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: kIsWeb ? FutureBuilder(
                                  future: file.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(snapshot.data as dynamic, fit: BoxFit.cover),
                                      );
                                    }
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                ) : null,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                                  ),
                                ),
                              )
                            ],
                          );
                        }
                      ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Product Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController, 
                decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController, 
                      decoration: const InputDecoration(labelText: 'Price (LKR) *', border: OutlineInputBorder()), 
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Valid Price req.' : null,
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController, 
                      decoration: const InputDecoration(labelText: 'Stock Qty *', border: OutlineInputBorder()), 
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || int.tryParse(value) == null ? 'Valid Qty req.' : null,
                    )
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Delivery Available'),
                value: _deliveryAvailable,
                onChanged: (val) { setState(() { _deliveryAvailable = val; }); },
                activeColor: Colors.green,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProduct,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PUBLISH PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
