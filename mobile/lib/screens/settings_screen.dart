import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisk_app/screens/profile_editor_screens.dart';
import 'package:nisk_app/main.dart';
import 'package:nisk_app/screens/suggestions_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkThemeEnabled = false;
  String _selectedLanguage = 'en'; // Store locale code (en, si, ta)

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _darkThemeEnabled = prefs.getBool('isDarkMode') ?? false;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _selectedLanguage = prefs.getString('app_locale') ?? context.locale.languageCode;
      });
    }
  }

  String _getLanguageDisplayName(String localeCode) {
    switch (localeCode) {
      case 'si':
        return 'සිංහල (Sinhala)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'en':
      default:
        return 'English';
    }
  }

  Future<void> _toggleDarkMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', val);
    if (mounted) {
      setState(() {
        _darkThemeEnabled = val;
      });
    }
    globalThemeMode.value = val ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _changeLanguage(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', localeCode);
    
    if (mounted) {
      setState(() {
        _selectedLanguage = localeCode;
      });

      // Change the app locale
      await context.setLocale(Locale(localeCode));
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${_getLanguageDisplayName(localeCode)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        )
      );
    }
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
          _buildSectionHeader('Profile Administration', isDark),
          _buildListTile(
            title: 'Personal Information',
            subtitle: 'Update your name, email, and location',
            icon: Icons.person_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences', isDark),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Get alerts for messages, bookings and orders',
            icon: Icons.notifications_active_outlined,
            value: _notificationsEnabled,
            onChanged: (val) async {
               final prefs = await SharedPreferences.getInstance();
               await prefs.setBool('notifications_enabled', val);
               if (mounted) setState(() => _notificationsEnabled = val);
            },
          ),
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.language, color: Colors.blue.shade700),
              ),
              title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_getLanguageDisplayName(_selectedLanguage), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                _showLanguagePicker();
              },
            ),
          ),
          _buildSwitchTile(
            title: 'Dark Theme',
            subtitle: 'Switch to dark mode interface',
            icon: Icons.dark_mode_outlined,
            value: _darkThemeEnabled,
            onChanged: _toggleDarkMode,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Support & Feedback', isDark),
          _buildListTile(
            title: 'Suggestion Box',
            subtitle: 'Share your ideas to improve the platform',
            icon: Icons.lightbulb_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionsScreen()));
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.grey.shade300 : const Color(0xFF1B3B6F),
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
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
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
          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.purple.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.green,
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
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              _buildLangOption('en', 'English', '🇬🇧'),
              _buildLangOption('si', 'සිංහල (Sinhala)', '🇱🇰'),
              _buildLangOption('ta', 'தமிழ் (Tamil)', '🇱🇰'),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Widget _buildLangOption(String localeCode, String langName, String flag) {
    bool isSelected = _selectedLanguage == localeCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 32)),
      title: Text(langName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green, size: 28) : null,
      tileColor: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
      onTap: () => _changeLanguage(localeCode),
    );
  }
}
