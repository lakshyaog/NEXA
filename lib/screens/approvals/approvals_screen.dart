import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../models/expense.dart';
import '../../state/expense_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/status_chip.dart';
import 'expense_detail_screen.dart';
import 'expense_form_screen.dart';

final expenseMoney =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  static const _tabs = {
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesStreamProvider);
    final tab = ref.watch(expenseTabProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Approvals')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kShellBottomInset),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ExpenseFormScreen(),
          )),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Raise expense'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                for (final entry in _tabs.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: tab == entry.key,
                      onSelected: (_) =>
                          ref.read(expenseTabProvider.notifier).set(entry.key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView(
              value: expenses,
              onRetry: () => ref.invalidate(expensesStreamProvider),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text('No ${_tabs[tab]!.toLowerCase()} expenses.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ExpenseTile(expense: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});
  final Expense expense;

  Color get _color => switch (expense.status) {
        'approved' => Colors.green,
        'rejected' => Colors.redAccent,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expenseMoney.format(expense.amount),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${expense.employeeName} • ${expense.category}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              StatusChip(
                label: expense.status[0].toUpperCase() +
                    expense.status.substring(1),
                color: _color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
