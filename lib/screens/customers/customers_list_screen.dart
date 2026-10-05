import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/status_colors.dart';
import '../../models/customer.dart';
import '../../state/customer_providers.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/async_view.dart';
import '../../widgets/status_chip.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(filteredCustomersProvider);
    final status = ref.watch(customerStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers & Leads')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kShellBottomInset),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const CustomerFormScreen(),
          )),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add lead'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              hint: 'Search by name or mobile',
              onChanged: (v) =>
                  ref.read(customerSearchProvider.notifier).set(v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: status == null,
                    onSelected: (_) => ref
                        .read(customerStatusFilterProvider.notifier)
                        .set(null),
                  ),
                ),
                for (final s in leadStatuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: status == s,
                      onSelected: (_) => ref
                          .read(customerStatusFilterProvider.notifier)
                          .set(s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView(
              value: customers,
              onRetry: () => ref.invalidate(customersStreamProvider),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CustomerTile(customer: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(customer: customer),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(customer.mobile,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              StatusChip(
                label: customer.status,
                color: leadStatusColor(customer.status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
