class DashboardStats {
  const DashboardStats({
    required this.employeesTotal,
    required this.employeesActive,
    required this.presentToday,
    required this.customersTotal,
    required this.leadsByStatus,
    required this.pendingApprovals,
    required this.collectionsToday,
  });

  final int employeesTotal;
  final int employeesActive;
  final int presentToday;
  final int customersTotal;
  final Map<String, int> leadsByStatus;
  final int pendingApprovals;
  final double collectionsToday;

  int get absentToday =>
      (employeesActive - presentToday).clamp(0, employeesActive);

  double get attendanceRate =>
      employeesActive == 0 ? 0 : presentToday / employeesActive;

  bool get isEmpty =>
      employeesTotal == 0 && customersTotal == 0 && pendingApprovals == 0;
}
