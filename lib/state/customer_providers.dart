import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import 'dashboard_providers.dart';
import 'employee_providers.dart';

final customerServiceProvider = Provider((ref) => CustomerService(
      ref.watch(firestoreProvider),
      ref.watch(auditServiceProvider),
    ));

final customersStreamProvider = StreamProvider.autoDispose<List<Customer>>(
  (ref) => ref.watch(customerServiceProvider).watchAll(),
);

final customerDocumentsProvider = StreamProvider.autoDispose
    .family<List<CustomerDocument>, String>(
  (ref, customerId) =>
      ref.watch(customerServiceProvider).watchDocuments(customerId),
);

class CustomerSearch extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final customerSearchProvider =
    NotifierProvider.autoDispose<CustomerSearch, String>(CustomerSearch.new);

/// `null` means "all statuses".
class CustomerStatusFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final customerStatusFilterProvider =
    NotifierProvider.autoDispose<CustomerStatusFilter, String?>(
  CustomerStatusFilter.new,
);

final filteredCustomersProvider =
    Provider.autoDispose<AsyncValue<List<Customer>>>((ref) {
  final list = ref.watch(customersStreamProvider);
  final query = ref.watch(customerSearchProvider).trim().toLowerCase();
  final status = ref.watch(customerStatusFilterProvider);

  return list.whenData((customers) => customers.where((c) {
        final matchesQuery = query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            c.mobile.contains(query);
        final matchesStatus = status == null || c.status == status;
        return matchesQuery && matchesStatus;
      }).toList());
});
