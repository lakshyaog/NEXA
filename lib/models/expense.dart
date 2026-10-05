import 'package:cloud_firestore/cloud_firestore.dart';

const expenseCategories = [
  'Travel',
  'Food',
  'Accommodation',
  'Fuel',
  'Office Supplies',
  'Other',
];

class Expense {
  const Expense({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.category,
    required this.description,
    required this.status,
    this.receiptUrl,
    this.rejectionReason,
    this.createdAt,
    this.decidedAt,
    this.decidedBy,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String category;
  final String description;

  /// `pending`, `approved` or `rejected`.
  final String status;

  final String? receiptUrl;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;

  bool get isPending => status == 'pending';

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Expense(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeName: d['employeeName'] ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      category: d['category'] ?? 'Other',
      description: d['description'] ?? '',
      status: d['status'] ?? 'pending',
      receiptUrl: d['receiptUrl'],
      rejectionReason: d['rejectionReason'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      decidedAt: (d['decidedAt'] as Timestamp?)?.toDate(),
      decidedBy: d['decidedBy'],
    );
  }
}
