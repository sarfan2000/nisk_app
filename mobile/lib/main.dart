import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
// No presets import needed
import 'package:nisk_app/screens/home_screen.dart';
import 'package:nisk_app/screens/login_screen.dart';
import 'package:nisk_app/screens/profile_screen.dart';
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

final ValueNotifier<ThemeMode> globalThemeMode = ValueNotifier(ThemeMode.light);
final ValueNotifier<String> globalLanguage = ValueNotifier('English');

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('x-auth-token');
    
    // Also load saved theme & language
    final isDark = prefs.getBool('isDarkMode') ?? false;
    globalThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    final savedLang = prefs.getString('language') ?? 'English';
    globalLanguage.value = savedLang;
    
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: globalThemeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'NISK App',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3B6F), brightness: Brightness.light),
            textTheme: GoogleFonts.poppinsTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3B6F), brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF121212),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            cardColor: const Color(0xFF1E1E1E),
            useMaterial3: true,
          ),
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          home: _isLoading 
              ? const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1B3B6F))))
              : (_isLoggedIn ? const HomeScreen() : const LoginScreen()),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      }
    );
  }
}

