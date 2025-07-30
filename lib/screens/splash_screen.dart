import 'package:flutter/material.dart';
import 'package:optiroute/screens/homescreen.dart';
import 'package:optiroute/screens/login_screen.dart';
import 'package:optiroute/services/auth_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatusAndNavigate();
  }

  Future<void> _checkAuthStatusAndNavigate() async {
    // Wait for AuthService to finish auto-login attempt
    await Provider.of<AuthService>(context, listen: false).isLoading; // Await initial loading state

    // Now check the authentication status
    final authService = Provider.of<AuthService>(context, listen: false);

    // Give it a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (authService.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the theme's colors for the splash screen
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary, // Primary color background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo/icon
            Icon(
              Icons.alt_route, // Example icon, replace with your actual logo
              size: 150,
              color: colorScheme.onPrimary, // Icon color contrasting with background
            ),
            const SizedBox(height: 20),
            Text(
              'OptiRoute',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary, // Text color contrasting with background
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Smart Route Companion',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary), // Loading indicator color
            ),
          ],
        ),
      ),
    );
  }
}