import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
// No presets import needed
import 'package:nisk_app/screens/home_screen.dart';
import 'package:nisk_app/screens/login_screen.dart';
import 'package:nisk_app/screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ta'), Locale('si')],
        path: 'assets/locales',
        fallbackLocale: const Locale('en'),
        child: DevicePreview(
          enabled: !kReleaseMode,
          builder: (context) => const NiskApp(),
        ),
      )
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Text(
                'CRITICAL STARTUP ERROR:\n$e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      )
    );
  }
}

final ValueNotifier<ThemeMode> globalThemeMode = ValueNotifier(ThemeMode.light);

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
    
    // Also load saved theme
    final isDark = prefs.getBool('isDarkMode') ?? false;
    globalThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
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
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, primary: Colors.black, secondary: const Color(0xFFF57224), brightness: Brightness.light),
            scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            textTheme: GoogleFonts.interTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: false,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, primary: Colors.white, secondary: const Color(0xFFF57224), brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF000000),
            textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF000000),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            cardColor: const Color(0xFF141414),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            useMaterial3: true,
          ),
          useInheritedMediaQuery: true,
          locale: context.locale, // Overridden if DevicePreview wants to inject? We merge them manually for prod: context.locale
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
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

