import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'package:nisk_app/screens/settings_screen.dart';
import 'package:nisk_app/screens/profile_editor_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeRole = 'Loading...';
  String _name = 'User Profile'; // Ideally fetch from DB
  String? _profilePic;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeRole = prefs.getString('activeRole') ?? 'Buyer';
      _profilePic = prefs.getString('profilePic');
      if (_profilePic != null && _profilePic!.isEmpty) _profilePic = null;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
       setState(() => _isUploading = true);
       try {
         final response = await ApiService().postMultipart(
           '/auth/upload-profile-pic',
           {},
           [pickedFile]
         );

         String newPic = response['profilePic'];
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('profilePic', newPic);

         setState(() {
            _profilePic = newPic;
            _isUploading = false;
         });
         
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
       } catch (e) {
         setState(() => _isUploading = false);
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload picture: $e')));
       }
    }
  }

  String? _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    // Strip "/api" from API base URL to point to root uploads dir
    String baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    return '$baseUrl/${path.replaceAll('\\', '/')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B3B6F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1B3B6F),
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _getImageUrl(_profilePic) != null
                              ? NetworkImage(_getImageUrl(_profilePic)!)
                              : null,
                          child: _getImageUrl(_profilePic) == null
                              ? const Icon(Icons.person, size: 60, color: Color(0xFF1B3B6F))
                              : null,
                        ),
                        if (_isUploading)
                          const Positioned.fill(child: CircularProgressIndicator(color: Colors.white)),
                        if (!_isUploading)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active Mode: ${_activeRole.toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileOption(context, Icons.settings, 'Account Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
            _buildProfileOption(context, Icons.security, 'Privacy & Security', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            }),
            _buildProfileOption(context, Icons.help_outline, 'Help & Support', () {}),
            const Divider(height: 40),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
              onTap: () async {
                await AuthService().logout();
                if (mounted) {
                   Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1B3B6F)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
