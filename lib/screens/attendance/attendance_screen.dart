import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../models/attendance.dart';
import '../../state/attendance_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/status_chip.dart';
import '../branches/branches_list_screen.dart';
import 'check_in_sheet.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredAttendanceProvider);
    final dateKey = ref.watch(attendanceDateProvider);
    final filter = ref.watch(attendanceFilterProvider);
    final selectedDate = DateTime.parse(dateKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            tooltip: 'Branches & geofence',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const BranchesListScreen(),
            )),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kShellBottomInset),
        child: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            builder: (_) => const CheckInSheet(),
          ),
          icon: const Icon(Icons.my_location),
          label: const Text('Test check-in'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('d MMM yyyy').format(selectedDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        ref.read(attendanceDateProvider.notifier).set(picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in AttendanceStatusFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        AttendanceStatusFilter.all => 'All',
                        AttendanceStatusFilter.present => 'Present',
                        AttendanceStatusFilter.rejected => 'Rejected',
                      }),
                      selected: filter == f,
                      onSelected: (_) =>
                          ref.read(attendanceFilterProvider.notifier).set(f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView(
              value: records,
              onRetry: () => ref.invalidate(attendanceStreamProvider),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No attendance records for this day.\n'
                        'Use "Test check-in" to record one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AttendanceTile(record: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${record.branchName} • '
                    '${record.distanceMeters.round()} m from centre',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (record.checkInAt != null)
                    Text(
                      DateFormat('h:mm a').format(record.checkInAt!),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                ],
              ),
            ),
            StatusChip(
              label: record.isPresent ? 'Present' : 'Rejected',
              color: record.isPresent ? Colors.green : Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }
}
