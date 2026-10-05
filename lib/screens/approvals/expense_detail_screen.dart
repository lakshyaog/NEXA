import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/expense_service.dart';
import '../../state/expense_detail_provider.dart';
import '../../state/expense_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/status_chip.dart';
import 'approvals_screen.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final String expenseId;

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  /// Guards against repeated taps while a decision is in flight. The
  /// Firestore transaction is the real safeguard; this keeps the UI honest.
  bool _deciding = false;
  String? _error;

  Future<void> _decide({required bool approve}) async {
    if (_deciding) return;

    String? reason;
    if (!approve) {
      reason = await _askRejectionReason();
      if (reason == null) return; // Cancelled.
    }

    setState(() {
      _deciding = true;
      _error = null;
    });

    try {
      await ref.read(expenseServiceProvider).decide(
            expenseId: widget.expenseId,
            approve: approve,
            rejectionReason: reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(approve ? 'Expense approved.' : 'Expense rejected.')),
        );
      }
    } on AlreadyDecidedException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Could not save the decision. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject expense'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Required',
            ),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Please give a reason (at least 3 characters)'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    final expense = ref.watch(expenseByIdProvider(widget.expenseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Expense detail')),
      body: AsyncView(
        value: expense,
        onRetry: () => ref.invalidate(expenseByIdProvider(widget.expenseId)),
        data: (e) {
          if (e == null) {
            return const Center(child: Text('This expense no longer exists.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expenseMoney.format(e.amount),
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(
                          label:
                              e.status[0].toUpperCase() + e.status.substring(1),
                          color: switch (e.status) {
                            'approved' => Colors.green,
                            'rejected' => Colors.redAccent,
                            _ => Colors.orange,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Field(label: 'Employee', value: e.employeeName),
                    _Field(label: 'Category', value: e.category),
                    if (e.description.isNotEmpty)
                      _Field(label: 'Description', value: e.description),
                    if (e.createdAt != null)
                      _Field(
                        label: 'Raised on',
                        value: DateFormat('d MMM yyyy, h:mm a')
                            .format(e.createdAt!),
                      ),
                    if (e.decidedBy != null)
                      _Field(label: 'Decided by', value: e.decidedBy!),
                    if (e.rejectionReason != null)
                      _Field(
                          label: 'Rejection reason', value: e.rejectionReason!),
                  ],
                ),
              ),
              if (e.receiptUrl != null) ...[
                const SizedBox(height: 16),
                const Text('Receipt',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    e.receiptUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Receipt image could not be loaded.'),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!),
                ),
              ],
              const SizedBox(height: 24),
              if (e.isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _deciding ? null : () => _decide(approve: false),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _deciding ? null : () => _decide(approve: true),
                        icon: _deciding
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check),
                        label: Text(_deciding ? 'Saving...' : 'Approve'),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    'This expense was already ${e.status}.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
}
