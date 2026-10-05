import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/date_key.dart';
import '../models/dashboard_stats.dart';
import 'auth_providers.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

typedef _Snapshot = QuerySnapshot<Map<String, dynamic>>;

Stream<_Snapshot> _watch(
  Ref ref,
  String collection, {
  String? field,
  Object? equalTo,
}) {
  final base = ref.watch(firestoreProvider).collection(collection);
  final query = field == null ? base : base.where(field, isEqualTo: equalTo);
  return query.snapshots();
}

final _employeesSnapshot =
    StreamProvider.autoDispose<_Snapshot>((ref) => _watch(ref, 'employees'));

final _customersSnapshot =
    StreamProvider.autoDispose<_Snapshot>((ref) => _watch(ref, 'customers'));

final _attendanceTodaySnapshot = StreamProvider.autoDispose<_Snapshot>(
  (ref) => _watch(ref, 'attendance',
      field: 'date', equalTo: dateKey(DateTime.now())),
);

final _pendingExpensesSnapshot = StreamProvider.autoDispose<_Snapshot>(
  (ref) => _watch(ref, 'expenses', field: 'status', equalTo: 'pending'),
);

final _collectionsTodaySnapshot = StreamProvider.autoDispose<_Snapshot>(
  (ref) => _watch(ref, 'collections',
      field: 'date', equalTo: dateKey(DateTime.now())),
);

/// Live dashboard figures.
///
/// Built from snapshot streams rather than a one-shot read because the shell
/// keeps every tab mounted in an `IndexedStack`; a future would be fetched
/// once and then go stale as soon as data changed on another tab.
final dashboardStatsProvider =
    Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  // The admin profile document must exist before any rule-guarded read.
  final profile = ref.watch(adminProfileProvider);
  if (profile.isLoading) return const AsyncValue.loading();
  if (profile.hasError) {
    return AsyncValue.error(profile.error!, profile.stackTrace!);
  }

  final sources = [
    ref.watch(_employeesSnapshot),
    ref.watch(_customersSnapshot),
    ref.watch(_attendanceTodaySnapshot),
    ref.watch(_pendingExpensesSnapshot),
    ref.watch(_collectionsTodaySnapshot),
  ];

  for (final source in sources) {
    if (source.hasError) {
      return AsyncValue.error(source.error!, source.stackTrace!);
    }
  }
  if (sources.any((s) => !s.hasValue)) return const AsyncValue.loading();

  final employees = sources[0].value!.docs;
  final customers = sources[1].value!.docs;
  final attendance = sources[2].value!.docs;

  return AsyncValue.data(DashboardStats(
    employeesTotal: employees.length,
    employeesActive:
        employees.where((d) => d.data()['status'] != 'inactive').length,
    presentToday:
        attendance.where((d) => d.data()['status'] == 'present').length,
    customersTotal: customers.length,
    pendingApprovals: sources[3].value!.docs.length,
    collectionsToday: sources[4].value!.docs.fold<double>(
      0,
      (total, doc) => total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
    ),
    leadsByStatus: {
      for (final status in leadStatuses)
        status: customers.where((d) => d.data()['status'] == status).length,
    },
  ));
});
