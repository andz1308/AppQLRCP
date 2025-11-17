import 'dart:io';

import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'utils/http_overrides.dart';

void main() {
  // For development only: allow self-signed certificates from localhost/emulator.
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinema App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
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
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Đợi 1 giây để hiển thị splash screen
    await Future.delayed(const Duration(seconds: 1));

    final user = await _authService.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      // Đã đăng nhập, chuyển đến màn hình tương ứng
      if (user.isCustomer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CustomerHomeScreen(user: user)),
        );
      } else if (user.isStaff) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => StaffHomeScreen(user: user)),
        );
      }
    } else {
      // Chưa đăng nhập, chuyển đến màn hình login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOrange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DAV',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rạp Chiếu Phim Hàng Đầu Việt Nam',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
