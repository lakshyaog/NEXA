import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/employee.dart';
import 'audit_service.dart';

class EmployeeService {
  EmployeeService(this._db, this._audit);
  final FirebaseFirestore _db;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('employees');

  Stream<List<Employee>> watchAll() => _col
      .orderBy('nameLower')
      .snapshots()
      .map((s) => s.docs.map(Employee.fromDoc).toList());

  /// Reserves a document id without writing anything.
  ///
  /// Lets a profile photo be uploaded to `employees/{id}/` before the record
  /// exists, so the stored file always sits under the id it belongs to rather
  /// than a placeholder that never matches.
  String newId() => _col.doc().id;

  Future<String> create(Employee e, {String? id}) async {
    final ref = id == null ? _col.doc() : _col.doc(id);
    await ref.set(e.toMap()..['createdAt'] = FieldValue.serverTimestamp());
    await _audit.log(
      action: 'employee_created',
      entity: 'employees/${ref.id}',
      summary: 'Created employee ${e.name}',
    );
    return ref.id;
  }

  Future<void> update(String id, Employee e) async {
    await _col.doc(id).update(e.toMap());
    await _audit.log(
      action: 'employee_updated',
      entity: 'employees/$id',
      summary: 'Updated employee ${e.name}',
    );
  }

  Future<void> setStatus(String id, String name, EmployeeStatus status) async {
    await _col.doc(id).update({'status': status.name});
    await _audit.log(
      action: 'employee_${status == EmployeeStatus.active ? 'activated' : 'deactivated'}',
      entity: 'employees/$id',
      summary:
          '${status == EmployeeStatus.active ? 'Activated' : 'Deactivated'} $name',
    );
  }
}
