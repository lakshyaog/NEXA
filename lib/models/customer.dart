import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.address,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String mobile;
  final String email;
  final String address;

  /// One of the PRD lead statuses: New, Contacted, Interested, Converted,
  /// Rejected.
  final String status;
  final DateTime? createdAt;

  factory Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Customer(
      id: doc.id,
      name: d['name'] ?? '',
      mobile: d['mobile'] ?? '',
      email: d['email'] ?? '',
      address: d['address'] ?? '',
      status: d['status'] ?? 'New',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': address,
        'status': status,
        'nameLower': name.toLowerCase(),
      };
}

/// A file attached to a customer, stored in Firebase Storage with its
/// metadata kept in Firestore.
class CustomerDocument {
  const CustomerDocument({
    required this.id,
    required this.customerId,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    this.uploadedAt,
  });

  final String id;
  final String customerId;
  final String type;
  final String fileUrl;
  final String fileName;
  final DateTime? uploadedAt;

  factory CustomerDocument.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CustomerDocument(
      id: doc.id,
      customerId: d['customerId'] ?? '',
      type: d['type'] ?? 'ID Proof',
      fileUrl: d['fileUrl'] ?? '',
      fileName: d['fileName'] ?? '',
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }
}
