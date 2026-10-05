import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeStatus { active, inactive }

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.designation,
    required this.branchId,
    required this.branchName,
    required this.status,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String mobile;
  final String email;
  final String designation;
  final String branchId;
  final String branchName;
  final EmployeeStatus status;
  final String? photoUrl;
  final DateTime? createdAt;

  bool get isActive => status == EmployeeStatus.active;

  factory Employee.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Employee(
      id: doc.id,
      name: d['name'] ?? '',
      mobile: d['mobile'] ?? '',
      email: d['email'] ?? '',
      designation: d['designation'] ?? '',
      branchId: d['branchId'] ?? '',
      branchName: d['branchName'] ?? '',
      status: (d['status'] == 'inactive')
          ? EmployeeStatus.inactive
          : EmployeeStatus.active,
      photoUrl: d['photoUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'mobile': mobile,
        'email': email,
        'designation': designation,
        'branchId': branchId,
        'branchName': branchName,
        'status': status.name,
        'photoUrl': photoUrl,
        'nameLower': name.toLowerCase(),
      };
}
