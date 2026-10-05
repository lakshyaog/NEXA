import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/app_colors.dart';
import '../../models/employee.dart';
import '../../state/employee_providers.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/async_view.dart';
import '../../widgets/status_chip.dart';
import 'employee_form_screen.dart';

class EmployeesListScreen extends ConsumerWidget {
  const EmployeesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(filteredEmployeesProvider);
    final filter = ref.watch(employeeStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kShellBottomInset),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EmployeeFormScreen(),
          )),
          icon: const Icon(Icons.add),
          label: const Text('Add employee'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              hint: 'Search by name',
              onChanged: (v) =>
                  ref.read(employeeSearchProvider.notifier).set(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in EmployeeStatusFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        EmployeeStatusFilter.all => 'All',
                        EmployeeStatusFilter.active => 'Active',
                        EmployeeStatusFilter.inactive => 'Inactive',
                      }),
                      selected: filter == f,
                      onSelected: (_) =>
                          ref.read(employeeStatusFilterProvider.notifier).set(f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView(
              value: employees,
              onRetry: () => ref.invalidate(employeesStreamProvider),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No employees found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _EmployeeTile(employee: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EmployeeFormScreen(employee: employee),
        )),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.lavender,
                backgroundImage: employee.photoUrl != null
                    ? NetworkImage(employee.photoUrl!)
                    : null,
                child: employee.photoUrl == null
                    ? Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      [employee.designation, employee.branchName]
                          .where((s) => s.isNotEmpty)
                          .join(' • '),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: employee.isActive ? 'Active' : 'Inactive',
                color: employee.isActive ? Colors.green : Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
