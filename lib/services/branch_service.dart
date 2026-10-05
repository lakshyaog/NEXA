import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/branch.dart';
import 'audit_service.dart';

class BranchService {
  BranchService(this._db, this._audit);
  final FirebaseFirestore _db;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('branches');

  Stream<List<Branch>> watchAll() =>
      _col.orderBy('nameLower').snapshots().map(
          (s) => s.docs.map(Branch.fromDoc).toList());

  Future<String> create(Branch b) async {
    final ref = await _col.add(b.toMap());
    await _audit.log(
      action: 'branch_created',
      entity: 'branches/${ref.id}',
      summary: 'Created branch ${b.name}',
    );
    return ref.id;
  }

  Future<void> update(String id, Branch b) async {
    await _col.doc(id).update(b.toMap());
    await _audit.log(
      action: 'branch_updated',
      entity: 'branches/$id',
      summary: 'Updated branch/geofence ${b.name}',
    );
  }
}
