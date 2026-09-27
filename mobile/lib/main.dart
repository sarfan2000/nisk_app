import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
// No presets import needed
import 'package:nisk_app/screens/home_screen.dart';
import 'package:nisk_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

class NiskApp extends StatelessWidget {
  const NiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NISK App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3B6F)), // Adjust with exact brand color
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
