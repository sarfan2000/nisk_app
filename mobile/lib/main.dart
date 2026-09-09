import 'package:flutter/material.dart';
import 'package:nisk_app/screens/home_screen.dart';
import 'package:nisk_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const NiskApp());
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
