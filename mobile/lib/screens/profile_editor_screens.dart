import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _location = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('userName') ?? '';
      _email = prefs.getString('userEmail') ?? '';
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService().put('/auth/update-profile', {
        'name': _name,
        'email': _email,
        'location': _location,
      });

      if (mounted) {
        // Save back to prefs so UI updates
        final prefs = await SharedPreferences.getInstance();
        if (response != null && response['user'] != null) {
          prefs.setString('userName', response['user']['name'] ?? '');
          prefs.setString('userEmail', response['user']['email'] ?? '');
        }
        
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Personal Details'), backgroundColor: const Color(0xFF1B3B6F), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Update Your Public Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                onSaved: (v) => _email = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'City / Location (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                onSaved: (v) => _location = v ?? '',
              ),
              const SizedBox(height: 32),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
            ],
          )
        )
      )
    );
  }
}


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _current = '';
  String _newPass = '';
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      await ApiService().put('/auth/change-password', {
        'currentPassword': _current,
        'newPassword': _newPass,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security Updated: Password Changed successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password'), backgroundColor: const Color(0xFF1B3B6F), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 60, color: Colors.blueGrey),
              const SizedBox(height: 16),
              const Text('Secure your account by updating your password below.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              TextFormField(
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: 'Current Password', 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure1 = !_obscure1),)
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _current = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'New Password', 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure2 = !_obscure2),)
                ),
                validator: (v) => v != null && v.length < 6 ? 'Minimum 6 characters' : null,
                onSaved: (v) => _newPass = v!,
              ),
              const SizedBox(height: 32),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3B6F), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('UPDATE PASSWORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
            ],
          )
        )
      )
    );
  }
}
