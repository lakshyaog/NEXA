import 'package:cloud_firestore/cloud_firestore.dart';

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.summary,
    required this.adminEmail,
    this.timestamp,
  });

  final String id;
  final String action;
  final String entity;
  final String summary;
  final String adminEmail;
  final DateTime? timestamp;

  factory AuditEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AuditEntry(
      id: doc.id,
      action: d['action'] ?? '',
      entity: d['entity'] ?? '',
      summary: d['summary'] ?? '',
      adminEmail: d['adminEmail'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
