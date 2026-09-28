import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
// No presets import needed
import 'package:nisk_app/screens/home_screen.dart';
import 'package:nisk_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const NiskApp(),
    ),
  );
}

class NiskApp extends StatefulWidget {
  const NiskApp({super.key});

  @override
  State<NiskApp> createState() => _NiskAppState();
}

class _NiskAppState extends State<NiskApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Check if token exists in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('x-auth-token');
    
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NISK App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3B6F)), // Brand color
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      // Core routing logic based on state
      home: _isLoading 
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1B3B6F))))
          : (_isLoggedIn ? const HomeScreen() : const LoginScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
