import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.branchId,
    required this.branchName,
    required this.date,
    required this.status,
    required this.distanceMeters,
    this.checkInAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String branchId;
  final String branchName;

  /// `yyyy-MM-dd`, kept as a string so day filters are simple equality
  /// queries that need no composite index on timestamp ranges.
  final String date;

  /// `present` when the check-in fell inside the geofence, `rejected` when it
  /// was outside.
  final String status;

  final double distanceMeters;
  final DateTime? checkInAt;
  final double? latitude;
  final double? longitude;

  bool get isPresent => status == 'present';

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AttendanceRecord(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeName: d['employeeName'] ?? '',
      branchId: d['branchId'] ?? '',
      branchName: d['branchName'] ?? '',
      date: d['date'] ?? '',
      status: d['status'] ?? 'rejected',
      distanceMeters: (d['distanceMeters'] as num?)?.toDouble() ?? 0,
      checkInAt: (d['checkInAt'] as Timestamp?)?.toDate(),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }
}

/// What happened when a check-in attempt was recorded.
enum CheckInOutcome {
  /// Inside the geofence, and marked present.
  accepted,

  /// Outside the geofence; the attempt was refused and logged.
  rejected,

  /// Already marked present today, so the attempt was not recorded.
  alreadyPresent,
}

/// Outcome of evaluating a GPS position against a branch geofence.
class GeofenceResult {
  const GeofenceResult({
    required this.accepted,
    required this.distanceMeters,
    required this.radiusMeters,
    required this.latitude,
    required this.longitude,
  });

  final bool accepted;
  final double distanceMeters;
  final double radiusMeters;
  final double latitude;
  final double longitude;

  double get metresOutside => distanceMeters - radiusMeters;
}
