import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'homescreen.dart'; // Import your HomeScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a timer that navigates to the HomeScreen after 5 seconds
    Timer(const Duration(seconds: 5), () {
      // Ensure the widget is still mounted before navigating
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme's color scheme for consistent styling
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary, // Use primary color for splash background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo or a prominent icon
            Icon(
              Icons.alt_route, // Example icon, you can replace with an Image.asset for a logo
              size: 100,
              color: colorScheme.onPrimary, // Icon color contrasting with primary background
            ),
            const SizedBox(height: 20),
            Text(
              'OptiRoute',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: colorScheme.onPrimary, // Text color contrasting with primary background
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Smart Navigation for Safer Journeys',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.8), // Subtitle with slight transparency
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
