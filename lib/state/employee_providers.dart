import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';

import '../models/employee.dart';
import '../services/audit_service.dart';
import '../services/branch_service.dart';
import '../services/employee_service.dart';
import '../services/cloudinary_file_storage.dart';
import '../services/file_storage.dart';
import '../services/firebase_file_storage.dart';
import 'auth_providers.dart';
import 'dashboard_providers.dart';

final firebaseStorageProvider =
    Provider<FirebaseStorage>((_) => FirebaseStorage.instance);

final dioProvider = Provider<Dio>((_) => Dio());

/// Picks the upload backend at runtime. Cloudinary is used when build-time
/// configuration supplies it; otherwise Firebase Storage, whose rules ship
/// with the repository, is used.
final fileStorageProvider = Provider<FileStorage>((ref) {
  if (AppConfig.usesCloudinary) {
    return CloudinaryFileStorage(ref.watch(dioProvider));
  }
  return FirebaseFileStorage(ref.watch(firebaseStorageProvider));
});

final auditServiceProvider = Provider(
  (ref) => AuditService(ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider)),
);

final employeeServiceProvider = Provider((ref) => EmployeeService(
      ref.watch(firestoreProvider),
      ref.watch(auditServiceProvider),
    ));

final branchServiceProvider = Provider((ref) => BranchService(
      ref.watch(firestoreProvider),
      ref.watch(auditServiceProvider),
    ));

final employeesStreamProvider = StreamProvider.autoDispose<List<Employee>>(
  (ref) => ref.watch(employeeServiceProvider).watchAll(),
);

final branchesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(branchServiceProvider).watchAll(),
);

enum EmployeeStatusFilter { all, active, inactive }

class EmployeeSearch extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final employeeSearchProvider =
    NotifierProvider.autoDispose<EmployeeSearch, String>(EmployeeSearch.new);

class EmployeeStatusFilterNotifier extends Notifier<EmployeeStatusFilter> {
  @override
  EmployeeStatusFilter build() => EmployeeStatusFilter.all;
  void set(EmployeeStatusFilter value) => state = value;
}

final employeeStatusFilterProvider = NotifierProvider.autoDispose<
    EmployeeStatusFilterNotifier, EmployeeStatusFilter>(
  EmployeeStatusFilterNotifier.new,
);

final filteredEmployeesProvider = Provider.autoDispose<AsyncValue<List<Employee>>>((ref) {
  final list = ref.watch(employeesStreamProvider);
  final query = ref.watch(employeeSearchProvider).trim().toLowerCase();
  final filter = ref.watch(employeeStatusFilterProvider);

  return list.whenData((employees) {
    return employees.where((e) {
      final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
      final matchesFilter = switch (filter) {
        EmployeeStatusFilter.all => true,
        EmployeeStatusFilter.active => e.isActive,
        EmployeeStatusFilter.inactive => !e.isActive,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  });
});

final auditLogProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(auditServiceProvider).watchRecent(),
);
