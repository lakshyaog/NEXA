import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import 'audit_service.dart';

class CustomerService {
  CustomerService(this._db, this._audit);
  final FirebaseFirestore _db;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('customers');

  Stream<List<Customer>> watchAll() => _col
      .orderBy('nameLower')
      .snapshots()
      .map((s) => s.docs.map(Customer.fromDoc).toList());

  Future<String> create(Customer c) async {
    final ref = await _col.add(
        c.toMap()..['createdAt'] = FieldValue.serverTimestamp());
    await _audit.log(
      action: 'customer_created',
      entity: 'customers/${ref.id}',
      summary: 'Created customer ${c.name} (${c.status})',
    );
    return ref.id;
  }

  Future<void> update(String id, Customer c) async {
    await _col.doc(id).update(c.toMap());
    await _audit.log(
      action: 'customer_updated',
      entity: 'customers/$id',
      summary: 'Updated customer ${c.name} (${c.status})',
    );
  }

  Stream<List<CustomerDocument>> watchDocuments(String customerId) => _db
      .collection('documents')
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((s) => s.docs.map(CustomerDocument.fromDoc).toList()
        ..sort((a, b) => (b.uploadedAt ?? DateTime(0))
            .compareTo(a.uploadedAt ?? DateTime(0))));

  Future<void> addDocument({
    required String customerId,
    required String customerName,
    required String type,
    required String fileUrl,
    required String fileName,
  }) async {
    final ref = await _db.collection('documents').add({
      'customerId': customerId,
      'type': type,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
    await _audit.log(
      action: 'document_uploaded',
      entity: 'documents/${ref.id}',
      summary: 'Uploaded $type for $customerName',
    );
  }
}
