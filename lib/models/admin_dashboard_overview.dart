// lib/models/admin_dashboard_overview.dart

class AdminDashboardOverview {
  final int recentReportedAccidents7Days;
  final Map<String, int> reportedAccidentsByStatus;
  final int totalCurrentSimulatedAccidents;
  final int totalHistoricalSimulatedAccidents;
  final int totalReportedAccidents;
  final int totalTravelLogs;
  final int totalUsers;
  final Map<String, int> usersByRole;

  AdminDashboardOverview({
    required this.recentReportedAccidents7Days,
    required this.reportedAccidentsByStatus,
    required this.totalCurrentSimulatedAccidents,
    required this.totalHistoricalSimulatedAccidents,
    required this.totalReportedAccidents,
    required this.totalTravelLogs,
    required this.totalUsers,
    required this.usersByRole,
  });

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) {
    return AdminDashboardOverview(
      recentReportedAccidents7Days: json['recent_reported_accidents_7_days'] as int,
      reportedAccidentsByStatus: Map<String, int>.from(json['reported_accidents_by_status']),
      totalCurrentSimulatedAccidents: json['total_current_simulated_accidents'] as int,
      totalHistoricalSimulatedAccidents: json['total_historical_simulated_accidents'] as int,
      totalReportedAccidents: json['total_reported_accidents'] as int,
      totalTravelLogs: json['total_travel_logs'] as int,
      totalUsers: json['total_users'] as int,
      usersByRole: Map<String, int>.from(json['users_by_role']),
    );
  }
}
