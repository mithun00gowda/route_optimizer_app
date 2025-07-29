import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For professional fonts

// Import the new home screen
import 'package:optiroute/screens/homescreen.dart';
import 'package:optiroute/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define a modern and professional color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700, // A deep blue as the primary color
          primary: Colors.blue.shade700,
          onPrimary: Colors.white,
          secondary: Colors.teal.shade400, // An accent color for secondary elements
          onSecondary: Colors.white,
          surface: Colors.white, // Background for cards, sheets etc.
          onSurface: Colors.grey.shade900,
          background: Colors.grey.shade50, // General screen background
          onBackground: Colors.grey.shade900,
          error: Colors.red.shade700,
          onError: Colors.white,
        ),
        // Apply Google Fonts for a professional look
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        // Customize AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 4.0, // Add a subtle shadow
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Customize ElevatedButton theme for consistent button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners for buttons
            ),
            elevation: 3.0, // Subtle shadow for buttons
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Customize Card theme
        cardTheme: CardThemeData(
          elevation: 4.0, // Shadow for cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for cards
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        // Input decoration theme for text fields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners for input fields
            borderSide: BorderSide.none, // No border by default
          ),
          filled: true,
          fillColor: Colors.grey.shade100, // Light grey background for inputs
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
          labelStyle: GoogleFonts.inter(color: Colors.grey.shade700),
        ),
        // Visual density for adaptive layout
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Set the new HomeScreen as the initial screen
      home: const SplashScreen(),
    );
  }
}
