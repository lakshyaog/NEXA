import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/audit_entry.dart';
import '../../state/employee_providers.dart';
import '../../widgets/async_view.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(auditLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: AsyncView(
        value: entries,
        onRetry: () => ref.invalidate(auditLogProvider),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No audit entries yet.\n'
                  'Creating or changing records will record entries here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AuditTile(entry: list[i]),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});
  final AuditEntry entry;

  IconData get _icon {
    if (entry.action.startsWith('employee')) return Icons.badge_outlined;
    if (entry.action.startsWith('branch')) return Icons.business_outlined;
    if (entry.action.startsWith('attendance')) return Icons.fingerprint;
    if (entry.action.startsWith('customer')) return Icons.person_outline;
    if (entry.action.startsWith('expense')) return Icons.receipt_long_outlined;
    if (entry.action.startsWith('document')) return Icons.description_outlined;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.summary,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.action} • ${entry.entity}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  Text(
                    [
                      entry.adminEmail,
                      if (entry.timestamp != null)
                        DateFormat('d MMM, h:mm a').format(entry.timestamp!),
                    ].join(' • '),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
