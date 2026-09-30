import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/education_dashboard.dart';
import 'package:nisk_app/screens/manpower/manpower_dashboard.dart';
import 'package:nisk_app/screens/products/products_dashboard.dart';

import 'package:nisk_app/screens/admin/admin_dashboard.dart';
import 'package:nisk_app/screens/delivery/delivery_dashboard.dart';
import 'package:nisk_app/screens/notifications/notifications_screen.dart';
import 'package:nisk_app/screens/search_screen.dart';
import 'package:nisk_app/screens/messages/messages_screen.dart';
import 'package:nisk_app/screens/profile_screen.dart';
import 'package:nisk_app/services/api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisk_app/services/auth_service.dart';

import 'package:nisk_app/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  int _unreadCount = 0;
  List<dynamic> _userRoles = [];
  String _activeRole = 'Buyer';
  int _currentIndex = 0;

  final Map<String, Widget> hubMapping = {
    'Teacher': const EducationDashboard(),
    'Student': const EducationDashboard(),
    'Worker': const ManpowerDashboard(),
    'Employer': const ManpowerDashboard(),
    'Seller': const ProductsDashboard(),
    'Admin': const AdminDashboard(),
    'Delivery': const DeliveryDashboard(),
  };

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeRole = prefs.getString('activeRole') ?? 'Buyer';
      String rolesJson = prefs.getString('roles') ?? '[]';
      _userRoles = jsonDecode(rolesJson);
    });
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      if (!isEnabled) {
        if (mounted) setState(() => _unreadCount = 0);
        return;
      }

      final response = await _apiService.get('/notifications/me');
      if (response != null && mounted) {
        int count = 0;
        for (var notif in response) {
          if (notif['read'] == false) count++;
        }
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('Failed to load home notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: globalLanguage,
      builder: (context, lang, _) {
        
        String homeLabel = 'Home';
        String searchLabel = 'Search';
        String messagesLabel = 'Messages';
        String profileLabel = 'Profile';

        if (lang == 'Sinhala (සිංහල)') {
          homeLabel = 'මුල් පිටුව';
          searchLabel = 'සොයන්න';
          messagesLabel = 'පණිවිඩ';
          profileLabel = 'ගිණුම';
        } else if (lang == 'Tamil (தமிழ்)') {
          homeLabel = 'முகப்பு';
          searchLabel = 'தேடல்';
          messagesLabel = 'செய்திகள்';
          profileLabel = 'கணக்கு';
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _currentIndex == 0 ? _buildHomeAppBar() : null,
          drawer: _currentIndex == 0 ? _buildRoleSwitcherDrawer() : null,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(context, lang),
              const SearchScreen(),
              const MessagesScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            selectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF1B3B6F),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: homeLabel),
              BottomNavigationBarItem(icon: const Icon(Icons.search), label: searchLabel),
              BottomNavigationBarItem(icon: const Icon(Icons.message_outlined), label: messagesLabel),
              BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: profileLabel),
            ],
          ),
        );
      }
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFFB11218)),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_active, color: Color(0xFFB11218)),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                // Refresh count when coming back
                _fetchUnreadCount();
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        ),
      ],
    );
  }

  Widget _buildHomeContent(BuildContext context, String lang) {
    String title = 'One Platform.\nEndless Opportunities.';
    String ed = 'EDUCATION ';
    String edSub = 'Learn. Teach. Grow';
    String mp = 'MANPOWER ';
    String mpSub = 'Find Jobs. Hire Talent';
    String pr = 'PRODUCTION & SALES ';
    String prSub = 'Buy. Sell. Expand';

    if (lang == 'Sinhala (සිංහල)') {
      title = 'එක් වේදිකාවක්.\nනිමක් නැති අවස්ථා.';
      ed = 'අධ්‍යාපනය';
      edSub = 'ඉගෙනගන්න. උගන්වන්න.';
      mp = 'ශ්‍රම බලකාය';
      mpSub = 'රැකියා සොයන්න. බඳවා ගන්න.';
      pr = 'නිෂ්පාදන සහ විකුණුම්';
      prSub = 'මිලදී ගන්න. විකුණන්න.';
    } else if (lang == 'Tamil (தமிழ்)') {
      title = 'ஒரு தளம்.\nமுடிவற்ற வாய்ப்புகள்.';
      ed = 'கல்வி';
      edSub = 'கற்றுக்கொள். கற்பி.';
      mp = 'மனிதவளம்';
      mpSub = 'வேலை தேடு. வேலை கொடு.';
      pr = 'உற்பத்தி மற்றும் விற்பனை';
      prSub = 'வாங்கு. விற்க.';
    }

    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Image.asset(
                  'assets/images/Nisk.jpeg',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'NISK Manpower Consultant (PVT) Ltd.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                   Text('CONNECT', style: TextStyle(color: Color(0xFF9E1B1E), fontWeight: FontWeight.bold, fontSize: 13)),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 6.0),
                     child: Text('•', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                   ),
                   Text('EMPOWER', style: TextStyle(color: Color(0xFFE5B914), fontWeight: FontWeight.bold, fontSize: 13)),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 6.0),
                     child: Text('•', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                   ),
                   Text('GROW', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!['Delivery', 'Admin'].contains(_activeRole)) ...[
                _buildLargeSectorButton(
                  context,
                  title: ed,
                  subtitle: edSub,
                  color: const Color(0xFFBA1A1A),
                  icon: Icons.school,
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const EducationDashboard()));
                  }
                ),
                const SizedBox(height: 14),
                _buildLargeSectorButton(
                  context,
                  title: mp,
                  subtitle: mpSub,
                  color: const Color(0xFFF1C40F),
                  icon: Icons.groups,
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const ManpowerDashboard()));
                  }
                ),
                const SizedBox(height: 14),
                _buildLargeSectorButton(
                  context,
                  title: pr,
                  subtitle: prSub,
                  color: const Color(0xFF278E33),
                  icon: Icons.shopping_cart,
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsDashboard()));
                  }
                ),
              ],
              if (_activeRole == 'Admin') ...[
                const SizedBox(height: 14),
                _buildLargeSectorButton(
                  context,
                  title: 'ADMINISTRATION',
                  subtitle: 'Manage System',
                  color: Colors.blueGrey,
                  icon: Icons.security,
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
                  }
                ),
              ],
              if (_activeRole == 'Delivery') ...[
                const SizedBox(height: 14),
                _buildLargeSectorButton(
                  context,
                  title: 'DELIVERY HUB',
                  subtitle: 'Rider Portal',
                  color: Colors.teal,
                  icon: Icons.local_shipping,
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryDashboard()));
                  }
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
    );
  }

  Widget _buildLargeSectorButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSwitcherDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: const Color(0xFF1B3B6F),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Mode', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_activeRole.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(alignment: Alignment.centerLeft, child: Text('Switch Profile Mode:', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _userRoles.length,
                itemBuilder: (context, index) {
                  final roleObj = _userRoles[index];
                  final roleName = roleObj['role'];
                  final bool isActive = _activeRole == roleName;

                  return ListTile(
                    leading: Icon(
                      Icons.account_circle, 
                      color: isActive ? const Color(0xFF1B3B6F) : Colors.grey
                    ),
                    title: Text(roleName, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                    trailing: isActive ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('activeRole', roleName);
                      setState(() {
                        _activeRole = roleName;
                      });
                      if (mounted) Navigator.pop(context); // close drawer
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Switched to $roleName Mode')));
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Apply for a new role'),
              onTap: () {
                _showAddRoleModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService().logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
      ),
    );
  }

  void _showAddRoleModal(BuildContext context) {
    final allPossibleRoles = ['Buyer', 'Seller', 'Worker', 'Employer', 'Teacher', 'Student', 'Delivery'];
    final existingRoleNames = _userRoles.map((r) => r['role'].toString()).toList();
    final missingRoles = allPossibleRoles.where((r) => !existingRoleNames.contains(r)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Account Profile'),
        content: missingRoles.isEmpty 
          ? const Text('You already have all available roles active!')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: missingRoles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.add_box, color: Colors.green),
                    title: Text(missingRoles[index]),
                    onTap: () async {
                      Navigator.pop(context); // Close dialog
                      try {
                        final updatedRoles = await AuthService().addRole(missingRoles[index]);
                        setState(() {
                           _userRoles = updatedRoles;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${missingRoles[index]} role successfully added!')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')));
                        }
                      }
                    },
                  );
                },
              ),
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))
        ],
      ),
    );
  }
}
