import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/date_key.dart';
import '../models/attendance.dart';
import '../models/branch.dart';
import '../models/employee.dart';
import 'audit_service.dart';
import 'location_service.dart';

class AttendanceService {
  AttendanceService(this._db, this._location, this._audit);

  final FirebaseFirestore _db;
  final LocationService _location;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('attendance');

  Stream<List<AttendanceRecord>> watchByDate(String date) => _col
      .where('date', isEqualTo: date)
      .snapshots()
      .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList()
        ..sort((a, b) =>
            (b.checkInAt ?? DateTime(0)).compareTo(a.checkInAt ?? DateTime(0))));

  /// Reads the device GPS position and measures it against [branch]'s
  /// configured radius. Throws [LocationFailure] if the position cannot be
  /// obtained; otherwise always returns a result, accepted or not.
  Future<GeofenceResult> evaluateGeofence(Branch branch) async {
    final position = await _location.currentPosition();
    final distance = _location.distanceBetween(
      fromLat: position.latitude,
      fromLng: position.longitude,
      toLat: branch.latitude,
      toLng: branch.longitude,
    );

    return GeofenceResult(
      accepted: distance <= branch.radiusMeters,
      distanceMeters: distance,
      radiusMeters: branch.radiusMeters,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Records the outcome of a geofence check-in attempt.
  ///
  /// Both accepted and rejected attempts are written, so a refusal leaves
  /// evidence rather than disappearing. The day's record uses a deterministic
  /// id (`{date}_{employeeId}`) so one employee cannot be marked present twice
  /// in a day, but a later rejected attempt must not erase an attendance that
  /// was already accepted — so an accepted record is never downgraded.
  Future<CheckInOutcome> recordCheckIn({
    required Employee employee,
    required Branch branch,
    required GeofenceResult result,
  }) async {
    final date = dateKey(DateTime.now());
    final docId = '${date}_${employee.id}';
    final ref = _col.doc(docId);

    final alreadyPresent = await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists && existing.data()?['status'] == 'present') {
        return true;
      }

      tx.set(ref, {
        'employeeId': employee.id,
        'employeeName': employee.name,
        'branchId': branch.id,
        'branchName': branch.name,
        'date': date,
        'status': result.accepted ? 'present' : 'rejected',
        'distanceMeters': result.distanceMeters,
        'radiusMeters': result.radiusMeters,
        'latitude': result.latitude,
        'longitude': result.longitude,
        'checkInAt': FieldValue.serverTimestamp(),
      });
      return false;
    });

    if (alreadyPresent) {
      await _audit.log(
        action: 'attendance_duplicate_ignored',
        entity: 'attendance/$docId',
        summary: '${employee.name} is already marked present today; '
            'the later attempt was not recorded',
      );
      return CheckInOutcome.alreadyPresent;
    }

    await _audit.log(
      action: result.accepted ? 'attendance_accepted' : 'attendance_rejected',
      entity: 'attendance/$docId',
      summary: result.accepted
          ? 'Check-in accepted for ${employee.name} at ${branch.name} '
              '(${result.distanceMeters.round()} m from centre)'
          : 'Check-in rejected for ${employee.name}: '
              '${result.distanceMeters.round()} m away, limit '
              '${result.radiusMeters.round()} m',
    );

    return result.accepted ? CheckInOutcome.accepted : CheckInOutcome.rejected;
  }
}
