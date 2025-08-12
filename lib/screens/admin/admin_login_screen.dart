// lib/screens/admin/admin_login_screen.dart

import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:optiroute/screens/login_screen.dart'; // Make sure this path is correct
import 'package:optiroute/screens/settings_screen.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../services/auth_service.dart';
import 'admin_dashboard_screen.dart'; // Import the new dashboard

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController =
  TextEditingController(); // Changed to username as per AuthService
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose(); // Dispose username controller
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        final String? errorMessage = await authService.login(
          _usernameController.text, // Use username
          _passwordController.text,
        );

        if (mounted) {
          if (errorMessage == null) {
            // Login successful, now check role
            if (authService.currentUser?.role == 'admin') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen()),
              );
            } else {
              // User is not an admin, log them out and show error
              await authService.logout(); // Log out non-admin user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Access Denied: Only administrators can log in here.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // Show error message from auth service
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('An unexpected error occurred: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // A simple check to prevent this screen from being viewed on mobile
    if (!kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          actions: [
            IconButton(
              // CORRECTED LINE HERE: Use pushReplacement for route objects
              onPressed: () {
                // Wrap in a function
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'This page is for web access only. Please use the mobile application.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Admin Portal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle:
        TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Adjust card width based on screen size
              double cardWidth =
              constraints.maxWidth > 800 ? 500 : (constraints.maxWidth * 0.7);
              if (cardWidth < 350) cardWidth = 350; // Minimum width

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Card(
                  elevation: 12, // Increased elevation for a more prominent look
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(20), // More rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48.0), // Increased padding
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 80, // Larger icon
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Admin Portal Login', // More descriptive title
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                              // Use displaySmall for web
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48), // Increased spacing
                          TextFormField(
                            controller:
                            _usernameController, // Using username controller
                            decoration: const InputDecoration(
                              labelText: 'Username', // Changed label to Username
                              prefixIcon:
                              Icon(Icons.person), // Changed icon to person
                            ),
                            keyboardType:
                            TextInputType.text, // Changed keyboard type
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24), // Increased spacing
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 48), // Increased spacing
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              // Changed to ElevatedButton.icon
                              onPressed: _login,
                              icon: const Icon(Icons.login), // Added login icon
                              label: const Text('Log In'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16), // Larger button
                                textStyle: const TextStyle(
                                    fontSize: 18), // Larger text
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}