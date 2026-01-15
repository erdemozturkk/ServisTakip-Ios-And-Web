import 'package:flutter/material.dart';
import 'package:servis_takip/pages/auth/login_page.dart';
import 'package:servis_takip/pages/passenger/passenger_dashboard.dart';
import 'package:servis_takip/pages/driver/driver_dashboard.dart';
import 'package:servis_takip/pages/admin/admin_dashboard.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/models/user_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Servis Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Splash ekran için 2 saniye bekle
    await Future.delayed(const Duration(seconds: 2));

    final isAuthenticated = await _authService.loadAuthData();

    if (!mounted) return;

    if (isAuthenticated && _authService.currentUser != null) {
      final user = _authService.currentUser!;
      
      // Kullanıcı rolüne göre yönlendir
      Widget destination;
      switch (user.role) {
        case UserRole.passenger:
          destination = const PassengerDashboard();
          break;
        case UserRole.driver:
          destination = const DriverDashboard();
          break;
        case UserRole.admin:
          destination = const AdminDashboard();
          break;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Servis Takip',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

