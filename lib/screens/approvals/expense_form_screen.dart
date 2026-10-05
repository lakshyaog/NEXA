import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/validators.dart';
import '../../models/employee.dart';
import '../../models/expense.dart';
import '../../state/employee_providers.dart';
import '../../state/expense_providers.dart';
import '../../state/notification_providers.dart';
import 'approvals_screen.dart';

/// Raises a pending expense. In production these would come from the employee
/// app; this screen exists so the admin approval flow can be exercised.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  Employee? _employee;
  String _category = expenseCategories.first;
  File? _receipt;
  double? _progress;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) setState(() => _receipt = File(file.path));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_employee == null) {
      setState(() => _error = 'Please select an employee.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final service = ref.read(expenseServiceProvider);
    // Reserve the id first so the receipt is filed under the expense it
    // belongs to, which is what the storage rules are scoped around.
    final expenseId = service.newId();

    try {
      String? receiptUrl;
      if (_receipt != null) {
        final name = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        receiptUrl = await ref.read(fileStorageProvider).upload(
              path: 'expenses/$expenseId/$name',
              file: _receipt!,
              onProgress: (p) {
                if (mounted) setState(() => _progress = p);
              },
            );
      }

      final amount = double.parse(_amount.text.trim());
      await service.create(
            id: expenseId,
            employeeId: _employee!.id,
            employeeName: _employee!.name,
            amount: amount,
            category: _category,
            description: _description.text.trim(),
            receiptUrl: receiptUrl,
          );

      // Alert the admin that a decision is pending; tapping it deep links to
      // this expense's approval screen.
      await ref.read(notificationServiceProvider).showApprovalAlert(
            expenseId: expenseId,
            employeeName: _employee!.name,
            amount: expenseMoney.format(amount),
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Raise expense')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              employees.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load employees.'),
                data: (list) => list.isEmpty
                    ? const Text('Add an employee first.')
                    : DropdownButtonFormField<Employee>(
                        initialValue: _employee,
                        decoration: const InputDecoration(labelText: 'Employee'),
                        items: [
                          for (final e in list)
                            DropdownMenuItem(value: e, child: Text(e.name)),
                        ],
                        onChanged: (v) => setState(() => _employee = v),
                      ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '₹ '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in expenseCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => Validators.required(v, 'Description'),
              ),
              const SizedBox(height: 16),
              if (_receipt != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_receipt!, height: 150, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
              ],
              if (_progress != null) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickReceipt,
                icon: const Icon(Icons.attach_file),
                label: Text(_receipt == null
                    ? 'Attach receipt (optional)'
                    : 'Change receipt'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit for approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
