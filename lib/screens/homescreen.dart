import 'package:flutter/material.dart';
import 'package:optiroute/screens/routeoptimizer_screen.dart';
import 'package:optiroute/screens/report_screen.dart'; // Import the new report screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme's color scheme for consistent styling
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiRoute Dashboard'),
        centerTitle: true, // Center the title for a cleaner look
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards horizontally
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
              color: colorScheme.primary, // Use primary color for main action
            ),
            const SizedBox(height: 16), // Spacing between cards

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
              color: colorScheme.secondary, // Use secondary color for a different action
            ),
            const SizedBox(height: 16),

            // You can add more service cards here following the same pattern
            // Example:
            // _buildServiceCard(
            //   context: context,
            //   icon: Icons.history,
            //   title: 'View Past Routes',
            //   description: 'Review your previous optimized routes and incidents.',
            //   onTap: () {
            //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const PastRoutesScreen()));
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('Feature coming soon!')),
            //     );
            //   },
            //   color: Colors.orange.shade400,
            // ),
          ],
        ),
      ),
    );
  }

  // Helper method to build consistent service cards
  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      // Card theme is applied globally in main.dart
      child: InkWell( // InkWell provides the ripple effect on tap
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Match card border radius
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 48,
                color: color, // Use the provided color for the icon
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface, // Ensure text color contrasts with card surface
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Slightly faded description
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.7), // Arrow icon with a subtle color
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
