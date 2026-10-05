import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/audit_entry.dart';

/// Writes append-only audit trail entries. Firestore rules make this
/// collection create-only for admins, so entries can never be edited or
/// deleted once written.
class AuditService {
  AuditService(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<List<AuditEntry>> watchRecent({int limit = 100}) => _db
      .collection('audit_logs')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AuditEntry.fromDoc).toList());

  Future<void> log({
    required String action,
    required String entity,
    required String summary,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // Should not happen on authenticated screens.
    await _db.collection('audit_logs').add({
      'action': action,
      'entity': entity,
      'summary': summary,
      'adminId': user.uid,
      'adminEmail': user.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
