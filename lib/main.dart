// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optiroute/screens/admin/admin_dashboard_screen.dart'; // Admin Dashboard
import 'package:optiroute/screens/homescreen.dart';
import 'package:provider/provider.dart';

import 'package:optiroute/screens/admin/admin_login_screen.dart'; // Admin Login for Web
import 'package:optiroute/screens/splash_screen.dart';
import 'package:optiroute/services/auth_service.dart';
import 'package:optiroute/screens/login_screen.dart'; // Import your mobile LoginScreen

// MyApp (Mobile)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context); // Get the service instance

    return MaterialApp(
      title: 'OptiRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          primary: Colors.blue.shade700,
          onPrimary: Colors.white,
          secondary: Colors.teal.shade400,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.grey.shade900,
          background: Colors.grey.shade50,
          onBackground: Colors.grey.shade900,
          error: Colors.red.shade700,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 4.0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3.0,
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
          labelStyle: GoogleFonts.inter(color: Colors.grey.shade700),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<void>(
        future: authService.checkAuthStatusFuture, // Await the initial setup future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || authService.isLoading) {
            // Show splash screen while initialization is in progress
            return const SplashScreen(); // This is correct, always show splash during initial load
          } else {
            // After initialization, use Consumer to react to further auth changes
            return Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isAuthenticated) {
                  // Authenticated mobile user goes to Mobile Dashboard
                  return const HomeScreen();
                } else {
                  // Unauthenticated mobile user goes to the Mobile Login Screen
                  return const LoginScreen(); // <-- CHANGED: Direct to LoginScreen for mobile
                }
              },
            );
          }
        },
      ),
    );
  }
}

// AdminApp (Web)
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context); // Get the service instance

    return MaterialApp(
      title: 'OptiRoute Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple.shade700,
          primary: Colors.deepPurple.shade700,
          onPrimary: Colors.white,
          secondary: Colors.teal.shade400,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.grey.shade900,
          background: Colors.grey.shade50,
          onBackground: Colors.grey.shade900,
          error: Colors.red.shade700,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
          elevation: 4.0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3.0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
          labelStyle: GoogleFonts.inter(color: Colors.grey.shade700),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<void>(
        future: authService.checkAuthStatusFuture, // Await the initial setup future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || authService.isLoading) {
            // Show loading indicator while initialization is in progress for web
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            // After initialization, use Consumer to react to further auth changes
            return Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isAuthenticated) {
                  return const AdminDashboardScreen();
                } else {
                  return const AdminLoginScreen(); // Web users go to AdminLoginScreen
                }
              },
            );
          }
        },
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AuthService(),
        child: const AdminApp(), // AdminApp for web
      ),
    );
  } else {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AuthService(),
        child: const MyApp(), // MyApp for mobile
      ),
    );
  }
}