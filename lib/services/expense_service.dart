import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';
import 'audit_service.dart';

/// Raised when a decision is attempted on an expense that is no longer
/// pending, e.g. because Approve was tapped twice.
class AlreadyDecidedException implements Exception {
  const AlreadyDecidedException(this.status);
  final String status;

  @override
  String toString() => 'This expense was already $status.';
}

class ExpenseService {
  ExpenseService(this._db, this._auth, this._audit);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('expenses');

  Stream<List<Expense>> watchByStatus(String status) => _col
      .where('status', isEqualTo: status)
      .snapshots()
      .map((s) => s.docs.map(Expense.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0))));

  Future<String> create({
    required String employeeId,
    required String employeeName,
    required double amount,
    required String category,
    required String description,
    String? receiptUrl,
  }) async {
    final ref = await _col.add({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'category': category,
      'description': description,
      'status': 'pending',
      'receiptUrl': receiptUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _audit.log(
      action: 'expense_created',
      entity: 'expenses/${ref.id}',
      summary: 'Expense of $amount raised for $employeeName ($category)',
    );
    return ref.id;
  }

  /// Approves or rejects an expense inside a transaction.
  ///
  /// The transaction re-reads the document and refuses the write if the
  /// status is no longer `pending`, so repeated taps (or two devices acting
  /// at once) cannot produce a double state change.
  Future<void> decide({
    required String expenseId,
    required bool approve,
    String? rejectionReason,
  }) async {
    final admin = _auth.currentUser;
    final ref = _col.doc(expenseId);
    late final Expense expense;

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw const AlreadyDecidedException('removed');
      }
      final current = Expense.fromDoc(snapshot);
      if (!current.isPending) {
        throw AlreadyDecidedException(current.status);
      }
      expense = current;

      tx.update(ref, {
        'status': approve ? 'approved' : 'rejected',
        'rejectionReason': approve ? null : rejectionReason,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': admin?.email,
      });
    });

    await _audit.log(
      action: approve ? 'expense_approved' : 'expense_rejected',
      entity: 'expenses/$expenseId',
      summary: approve
          ? 'Approved expense of ${expense.amount} for ${expense.employeeName}'
          : 'Rejected expense of ${expense.amount} for '
              '${expense.employeeName}: $rejectionReason',
    );
  }
}
