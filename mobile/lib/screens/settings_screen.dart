import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

import 'package:nisk_app/screens/profile_editor_screens.dart';
import 'package:nisk_app/main.dart'; // To access globalThemeMode

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkThemeEnabled = false;
  bool _biometricEnabled = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkThemeEnabled = prefs.getBool('isDarkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _toggleDarkMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', val);
    setState(() {
      _darkThemeEnabled = val;
    });
    globalThemeMode.value = val ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() {
      _language = lang;
    });
    globalLanguage.value = lang;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language updated to $lang')));
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.black : const Color(0xFF1B3B6F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Account Administration'),
          _buildListTile(
            title: 'Change Password',
            subtitle: 'Secure your account',
            icon: Icons.lock_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Get alerts for messages, bookings and orders',
            icon: Icons.notifications_active_outlined,
            value: _notificationsEnabled,
            onChanged: (val) async {
               final prefs = await SharedPreferences.getInstance();
               await prefs.setBool('notifications_enabled', val);
               setState(() => _notificationsEnabled = val);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.language, color: Colors.blueGrey),
              title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_language),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                _showLanguagePicker();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: isDark ? Colors.grey.shade800 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
          _buildSwitchTile(
            title: 'Dark Theme',
            subtitle: 'Switch to dark mode interface',
            icon: Icons.dark_mode_outlined,
            value: _darkThemeEnabled,
            onChanged: _toggleDarkMode,
          ),

          const SizedBox(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                  await AuthService().logout();
                  if (mounted) {
                     Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
                  }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out Globally', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('NISK Super-App Version 2.0.1\n© 2026 NISK Platform', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF1B3B6F),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required IconData icon, required bool value, required Function(bool) onChanged}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.purple.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildLangOption('English'),
              _buildLangOption('Sinhala (සිංහල)'),
              _buildLangOption('Tamil (தமிழ்)'),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Widget _buildLangOption(String lang) {
    return ListTile(
      title: Text(lang, style: TextStyle(fontWeight: _language == lang ? FontWeight.bold : FontWeight.normal)),
      trailing: _language == lang ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () => _changeLanguage(lang),
    );
  }
}
