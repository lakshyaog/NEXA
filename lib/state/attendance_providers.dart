import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_key.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';
import 'dashboard_providers.dart';
import 'employee_providers.dart';

final locationServiceProvider = Provider((_) => const LocationService());

final attendanceServiceProvider = Provider((ref) => AttendanceService(
      ref.watch(firestoreProvider),
      ref.watch(locationServiceProvider),
      ref.watch(auditServiceProvider),
    ));

/// Selected day for the attendance list, as `yyyy-MM-dd`.
class AttendanceDate extends Notifier<String> {
  @override
  String build() => dateKey(DateTime.now());
  void set(DateTime date) => state = dateKey(date);
}

final attendanceDateProvider =
    NotifierProvider.autoDispose<AttendanceDate, String>(AttendanceDate.new);

enum AttendanceStatusFilter { all, present, rejected }

class AttendanceFilter extends Notifier<AttendanceStatusFilter> {
  @override
  AttendanceStatusFilter build() => AttendanceStatusFilter.all;
  void set(AttendanceStatusFilter value) => state = value;
}

final attendanceFilterProvider = NotifierProvider.autoDispose<AttendanceFilter,
    AttendanceStatusFilter>(AttendanceFilter.new);

final attendanceStreamProvider =
    StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final date = ref.watch(attendanceDateProvider);
  return ref.watch(attendanceServiceProvider).watchByDate(date);
});

final filteredAttendanceProvider =
    Provider.autoDispose<AsyncValue<List<AttendanceRecord>>>((ref) {
  final records = ref.watch(attendanceStreamProvider);
  final filter = ref.watch(attendanceFilterProvider);

  return records.whenData((list) => list.where((r) {
        return switch (filter) {
          AttendanceStatusFilter.all => true,
          AttendanceStatusFilter.present => r.isPresent,
          AttendanceStatusFilter.rejected => !r.isPresent,
        };
      }).toList());
});
