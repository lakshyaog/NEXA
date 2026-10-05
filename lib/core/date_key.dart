import 'package:intl/intl.dart';

final _formatter = DateFormat('yyyy-MM-dd');

/// Canonical `yyyy-MM-dd` key used for day-scoped Firestore documents and
/// equality filters, so "records for one day" stays a simple query.
String dateKey(DateTime date) => _formatter.format(date);
