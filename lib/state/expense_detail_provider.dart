import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import 'dashboard_providers.dart';

/// Live view of one expense, so a decision made elsewhere (or by a second
/// tap) is reflected immediately on the detail screen.
final expenseByIdProvider =
    StreamProvider.autoDispose.family<Expense?, String>((ref, id) {
  return ref
      .watch(firestoreProvider)
      .collection('expenses')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Expense.fromDoc(doc) : null);
});
