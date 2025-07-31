// lib/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:optiroute/services/api_services.dart';
import 'package:optiroute/models/models.dart' as models; // Alias models to avoid conflict with 'User' in services
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:optiroute/services/auth_service.dart';
import 'package:optiroute/screens/admin/admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String _currentTitle = 'Dashboard Overview';

  late Future<models.AdminDashboardOverview> _overviewFuture;
  late Future<List<models.User>> _usersFuture; // Explicitly use models.User
  late Future<List<models.AdminReportedAccident>> _reportedAccidentsFuture;
  late Future<List<models.TravelRate>> _travelRatesFuture;
  late Future<List<models.DailyTrip>> _dailyTripsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _overviewFuture = ApiService.getAdminDashboardOverview(context);
      _usersFuture = ApiService.getAllUsers(context);
      _reportedAccidentsFuture = ApiService.getAllReportedAccidents(context);
      _travelRatesFuture = ApiService.getUserTravelRates(context);
      _dailyTripsFuture = ApiService.getDailyTrips(context);
    });
  }

  void _onItemTapped(int index, String title) {
    setState(() {
      _selectedIndex = index;
      _currentTitle = title;
    });
  }

  // --- Widgets for each section (unchanged from previous version) ---
  Widget _buildOverviewContent() {
    return FutureBuilder<models.AdminDashboardOverview>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    'Error loading overview data: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No overview data available.'));
        } else {
          final overview = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Metrics', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildStatCard('Total Users', overview.totalUsers.toString(), Icons.group, Colors.blue),
                    _buildStatCard('Total Reported Accidents', overview.totalReportedAccidents.toString(), Icons.warning, Colors.orange),
                    _buildStatCard('Recent Accidents (7 Days)', overview.recentReportedAccidents7Days.toString(), Icons.new_releases, Colors.red),
                    _buildStatCard('Total Travel Logs', overview.totalTravelLogs.toString(), Icons.route, Colors.green),
                    _buildStatCard('Current Simulated Accidents', overview.totalCurrentSimulatedAccidents.toString(), Icons.traffic, Colors.deepPurple),
                    _buildStatCard('Historical Simulated Accidents', overview.totalHistoricalSimulatedAccidents.toString(), Icons.history, Colors.brown),
                  ],
                ),
                const SizedBox(height: 40),
                Text('Accidents by Status', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: overview.reportedAccidentsByStatus.entries.map((entry) =>
                          ListTile(
                            leading: _getStatusIcon(entry.key),
                            title: Text(
                              '${entry.key}: ${entry.value}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text('Users by Role', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: overview.usersByRole.entries.map((entry) =>
                          ListTile(
                            leading: Icon(entry.key == 'admin' ? Icons.security : Icons.person, color: Theme.of(context).colorScheme.secondary),
                            title: Text(
                              '${entry.key}: ${entry.value}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return Icon(Icons.info_outline, color: Colors.blue.shade700);
      case 'investigating': return Icon(Icons.search, color: Colors.orange.shade700);
      case 'resolved': return Icon(Icons.check_circle_outline, color: Colors.green.shade700);
      case 'duplicate': return Icon(Icons.copy, color: Colors.grey.shade700);
      case 'rejected': return Icon(Icons.cancel_outlined, color: Colors.red.shade700);
      default: return Icon(Icons.help_outline, color: Colors.grey.shade500);
    }
  }

  Widget _buildUsersContent() {
    return FutureBuilder<List<models.User>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users found.'));
        } else {
          final users = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Management', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PaginatedDataTable(
                      header: Text('User List', style: Theme.of(context).textTheme.titleLarge),
                      columns: const [
                        DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      source: UserDataSource(users, context, _loadData),
                      rowsPerPage: users.length < 10 ? users.length : 10,
                      showCheckboxColumn: false,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildIncidentsContent() {
    return FutureBuilder<List<models.AdminReportedAccident>>(
      future: _reportedAccidentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reported incidents found.'));
        } else {
          final incidents = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incident Reports', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PaginatedDataTable(
                      header: Text('Incident List', style: Theme.of(context).textTheme.titleLarge),
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Reporter', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Media', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Reported At', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      source: ReportedAccidentDataSource(incidents, context, _loadData),
                      rowsPerPage: incidents.length < 10 ? incidents.length : 10,
                      showCheckboxColumn: false,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildTravelAnalysisContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travel Analysis', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          FutureBuilder<List<models.TravelRate>>(
            future: _travelRatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading user travel rates: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No user travel rates data.'));
              } else {
                final travelRates = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Travel Rates', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PaginatedDataTable(
                          columns: const [
                            DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Trips', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Distance (km)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Duration (hrs)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Avg. Score', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          source: TravelRateDataSource(travelRates),
                          rowsPerPage: travelRates.length < 10 ? travelRates.length : 10,
                          showCheckboxColumn: false,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 30),
          FutureBuilder<List<models.DailyTrip>>(
            future: _dailyTripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading daily trips: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No daily trips data.'));
              } else {
                final dailyTrips = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Trips Overview', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PaginatedDataTable(
                          columns: const [
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Trip Count', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Distance (km)', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          source: DailyTripDataSource(dailyTrips),
                          rowsPerPage: dailyTrips.length < 10 ? dailyTrips.length : 10,
                          showCheckboxColumn: false,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Main Build Method for Layout ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                );
              }
              Fluttertoast.showToast(msg: 'Logged out successfully!');
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation (for web)
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.admin_panel_settings, color: colorScheme.onPrimary, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Admin Panel',
                        style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(0, 'Overview', Icons.dashboard),
                _buildDrawerItem(1, 'Users', Icons.people),
                _buildDrawerItem(2, 'Incidents', Icons.report),
                _buildDrawerItem(3, 'Travel Analysis', Icons.analytics),
                const Divider(),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverviewContent(),
                _buildUsersContent(),
                _buildIncidentsContent(),
                _buildTravelAnalysisContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          _onItemTapped(index, title);
        },
        selected: isSelected,
      ),
    );
  }
}

// --- DataTable Sources ---

class UserDataSource extends DataTableSource {
  final List<models.User> _users;
  final BuildContext _context;
  final VoidCallback _refreshData;

  UserDataSource(this._users, this._context, this._refreshData);

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final user = _users[index];
    return DataRow(cells: [
      DataCell(Text(user.username)),
      DataCell(Text(user.email)),
      DataCell(Text(user.role)),
      DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(user.createdAt)))),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showUpdateUserRoleDialog(user),
            tooltip: 'Update Role',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _confirmDeleteUser(user),
            tooltip: 'Delete User',
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _users.length;

  @override
  int get selectedRowCount => 0;

  void _showUpdateUserRoleDialog(models.User user) {
    String? selectedRole = user.role;
    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Role for ${user.username}'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              selectedRole = value;
            },
            decoration: const InputDecoration(labelText: 'New Role'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                Navigator.of(context).pop();
                if (selectedRole != null && selectedRole != user.role) {
                  try {
                    await ApiService.updateUserRole(_context, user.publicId, selectedRole!);
                    Fluttertoast.showToast(msg: 'User role updated successfully!');
                    _refreshData();
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Failed to update role: $e', backgroundColor: Colors.red);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(models.User user) {
    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete user "${user.username}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApiService.deleteUser(_context, user.publicId);
                  Fluttertoast.showToast(msg: 'User deleted successfully!');
                  _refreshData();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to delete user: $e', backgroundColor: Colors.red);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class ReportedAccidentDataSource extends DataTableSource {
  final List<models.AdminReportedAccident> _incidents;
  final BuildContext _context;
  final VoidCallback _refreshData;

  ReportedAccidentDataSource(this._incidents, this._context, this._refreshData);

  // New method to show media viewer dialog
  void _showMediaViewerDialog(List<String> mediaPaths) {
    if (mediaPaths.isEmpty) {
      Fluttertoast.showToast(msg: 'No media available for this incident.');
      return;
    }

    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600), // Max size for the dialog
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    itemCount: mediaPaths.length,
                    itemBuilder: (context, index) {
                      final mediaUrl = mediaPaths[index];
                      // Assuming media are images. For videos, you'd need a video player.
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          mediaUrl,
                          fit: BoxFit.contain, // Fit image within bounds
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                Text('Failed to load image: $error'),
                              ],
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (mediaPaths.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '${1}/${mediaPaths.length}', // Current page indicator (adjust to dynamic later if needed)
                      style: Theme.of(_context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _incidents.length) return null;
    final incident = _incidents[index];
    return DataRow(cells: [
      DataCell(Text(incident.id.toString())),
      DataCell(Text(incident.reportedByUsername)),
      DataCell(Text(incident.incidentType)),
      DataCell(
        DropdownButton<String>(
          value: incident.status,
          items: const [
            DropdownMenuItem(value: 'reported', child: Text('Reported')),
            DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
            DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
            DropdownMenuItem(value: 'duplicate', child: Text('Duplicate')),
            DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
          ],
          onChanged: (String? newStatus) async {
            if (newStatus != null && newStatus != incident.status) {
              try {
                await ApiService.updateReportedAccidentStatus(_context, incident.id, newStatus);
                Fluttertoast.showToast(msg: 'Incident status updated!');
                _refreshData();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to update status: $e', backgroundColor: Colors.red);
              }
            }
          },
        ),
      ),
      DataCell(Text('${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}')),
      DataCell(
        incident.mediaPaths.isNotEmpty
            ? Row(
          children: [
            const Icon(Icons.image, size: 20),
            Text('(${incident.mediaPaths.length})'),
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () {
                _showMediaViewerDialog(incident.mediaPaths); // Call the new method
              },
              tooltip: 'View Media',
            ),
          ],
        )
            : const Text('None'),
      ),
      DataCell(Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(incident.reportedAt)))),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _confirmDeleteIncident(incident),
            tooltip: 'Delete Incident',
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _incidents.length;

  @override
  int get selectedRowCount => 0;

  void _confirmDeleteIncident(models.AdminReportedAccident incident) {
    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete incident ID ${incident.id}? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApiService.deleteReportedAccident(_context, incident.id);
                  Fluttertoast.showToast(msg: 'Incident deleted successfully!');
                  _refreshData();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to delete incident: $e', backgroundColor: Colors.red);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class TravelRateDataSource extends DataTableSource {
  final List<models.TravelRate> _travelRates;

  TravelRateDataSource(this._travelRates);

  @override
  DataRow? getRow(int index) {
    if (index >= _travelRates.length) return null;
    final rate = _travelRates[index];
    return DataRow(cells: [
      DataCell(Text(rate.username)),
      DataCell(Text(rate.totalTrips.toString())),
      DataCell(Text(rate.totalDistanceKm.toStringAsFixed(2))),
      DataCell(Text(rate.totalDurationHours.toStringAsFixed(2))),
      DataCell(Text(rate.avgRouteScore.toStringAsFixed(1))),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _travelRates.length;

  @override
  int get selectedRowCount => 0;
}

class DailyTripDataSource extends DataTableSource {
  final List<models.DailyTrip> _dailyTrips;

  DailyTripDataSource(this._dailyTrips);

  @override
  DataRow? getRow(int index) {
    if (index >= _dailyTrips.length) return null;
    final trip = _dailyTrips[index];
    return DataRow(cells: [
      DataCell(Text(trip.date)),
      DataCell(Text(trip.tripCount.toString())),
      DataCell(Text(trip.totalDistanceKm.toStringAsFixed(2))),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _dailyTrips.length;

  @override
  int get selectedRowCount => 0;
}