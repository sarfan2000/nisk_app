import 'package:flutter/material.dart';
import 'package:nisk_app/services/auth_service.dart';
import 'package:nisk_app/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/Nisk.jpeg',
                  height: 120, // Adjust height as necessary
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'NISK App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3B6F), // Brand Blue
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CONNECT • EMPOWER • GROW',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, letterSpacing: 1.2),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Reset SMS sent!')));
                  },
                  child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF1B3B6F), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1B3B6F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              const SizedBox(height: 16),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Color(0xFF1B3B6F), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
