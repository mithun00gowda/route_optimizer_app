// lib/screens/homescreen.dart
import 'package:flutter/material.dart';
import 'package:optiroute/screens/routeoptimizer_screen.dart';
import 'package:optiroute/screens/report_screen.dart';
import 'package:optiroute/services/auth_service.dart'; // Import AuthService
import 'package:provider/provider.dart'; // Import provider
import 'package:optiroute/screens/login_screen.dart'; // Import LoginScreen
import 'package:optiroute/screens/new_page_screen.dart'; // Import the new page screen

import 'admin/admin_dashboard_screen.dart'; // Import AdminDashboardScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final authService = Provider.of<AuthService>(context); // Access AuthService

    // Check if the current user is an admin
    final bool isAdmin = authService.currentUser?.role == 'admin';
    print(isAdmin);
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiRoute Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              // After logout, navigate back to LoginScreen and remove all previous routes
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card for "Calculate Safe Route"
              _buildServiceCard(
                context: context,
                icon: Icons.alt_route,
                title: 'Calculate Safe Route',
                description: 'Find the most optimized and safest route for your journey.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteOptimizerScreen()),
                  );
                },
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
        
              // Card for "Report Accident or Road Jam"
              _buildServiceCard(
                context: context,
                icon: Icons.warning_amber_rounded,
                title: 'Report Incident',
                description: 'Help others by reporting accidents, road jams, or hazards.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportScreen()),
                  );
                },
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 16),
        
              // Card for "Explore New Feature" (My Reported Incidents)
              _buildServiceCard(
                context: context,
                icon: Icons.pages,
                title: 'My Reported Incidents',
                description: 'View and manage incidents you have reported.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewPageScreen()),
                  );
                },
                color: colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
        
              // Admin Dashboard Card (only visible to admins)
              if (isAdmin) // Conditionally render for admin users
                _buildServiceCard(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Dashboard',
                  description: 'Access administrative tools and overview.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                  },
                  color: Colors.deepPurple, // Distinct color for admin
                ),
              if (isAdmin) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent service cards (keep this the same)
  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
