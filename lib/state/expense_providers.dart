import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import 'auth_providers.dart';
import 'dashboard_providers.dart';
import 'employee_providers.dart';

final expenseServiceProvider = Provider((ref) => ExpenseService(
      ref.watch(firestoreProvider),
      ref.watch(firebaseAuthProvider),
      ref.watch(auditServiceProvider),
    ));

class ExpenseTab extends Notifier<String> {
  @override
  String build() => 'pending';
  void set(String value) => state = value;
}

final expenseTabProvider =
    NotifierProvider.autoDispose<ExpenseTab, String>(ExpenseTab.new);

final expensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final status = ref.watch(expenseTabProvider);
  return ref.watch(expenseServiceProvider).watchByStatus(status);
});
