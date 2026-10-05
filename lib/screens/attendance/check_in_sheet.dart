import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance.dart';
import '../../models/branch.dart';
import '../../models/employee.dart';
import '../../services/location_service.dart';
import '../../state/attendance_providers.dart';
import '../../state/employee_providers.dart';

/// Geofenced test check-in.
///
/// Flow: pick employee + branch -> request location permission -> read GPS ->
/// compare distance against the branch radius -> accept or reject, and write
/// the attempt either way.
class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({super.key});

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  Employee? _employee;
  Branch? _branch;
  bool _running = false;
  GeofenceResult? _result;
  CheckInOutcome? _outcome;
  LocationFailure? _failure;
  String? _error;

  Future<void> _runCheckIn() async {
    if (_running || _employee == null || _branch == null) return;
    setState(() {
      _running = true;
      _result = null;
      _outcome = null;
      _failure = null;
      _error = null;
    });

    final service = ref.read(attendanceServiceProvider);
    try {
      final result = await service.evaluateGeofence(_branch!);
      final outcome = await service.recordCheckIn(
        employee: _employee!,
        branch: _branch!,
        result: result,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _outcome = outcome;
        });
      }
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _failure = e);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Check-in could not be saved. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesStreamProvider);
    final branches = ref.watch(branchesStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Geofence test check-in',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Your current GPS position is compared against the selected '
              'branch radius.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),

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
            branches.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Could not load branches.'),
              data: (list) => list.isEmpty
                  ? const Text('Add a branch with a geofence first.')
                  : DropdownButtonFormField<Branch>(
                      initialValue: _branch,
                      decoration: const InputDecoration(labelText: 'Branch'),
                      items: [
                        for (final b in list)
                          DropdownMenuItem(
                            value: b,
                            child: Text(
                                '${b.name} (r = ${b.radiusMeters.round()} m)'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _branch = v),
                    ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(result: _result!, outcome: _outcome!),
            ],
            if (_failure != null) ...[
              const SizedBox(height: 20),
              _FailureCard(
                failure: _failure!,
                onOpenSettings: () {
                  final loc = ref.read(locationServiceProvider);
                  if (_failure!.problem == LocationProblem.serviceDisabled) {
                    loc.openLocationSettings();
                  } else {
                    loc.openAppSettings();
                  }
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
                  (_running || _employee == null || _branch == null)
                      ? null
                      : _runCheckIn,
              icon: _running
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location),
              label: Text(_running ? 'Reading GPS...' : 'Run check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.outcome});
  final GeofenceResult result;
  final CheckInOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final accepted = result.accepted;
    final duplicate = outcome == CheckInOutcome.alreadyPresent;
    final color = duplicate
        ? Colors.blueGrey
        : (accepted ? Colors.green : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                duplicate
                    ? Icons.info_outline
                    : (accepted ? Icons.check_circle : Icons.cancel),
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                duplicate
                    ? 'Already marked present'
                    : (accepted ? 'Attendance accepted' : 'Attendance rejected'),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            duplicate
                ? 'This employee was already marked present today, so today\'s '
                    'attendance was left unchanged.'
                : accepted
                    ? 'You are ${result.distanceMeters.round()} m from the '
                        'branch centre, inside the '
                        '${result.radiusMeters.round()} m geofence.'
                    : 'You are ${result.distanceMeters.round()} m from the '
                        'branch centre, which is '
                        '${result.metresOutside.round()} m outside the '
                        '${result.radiusMeters.round()} m geofence.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Position: ${result.latitude.toStringAsFixed(5)}, '
            '${result.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure, required this.onOpenSettings});
  final LocationFailure failure;
  final VoidCallback onOpenSettings;

  bool get _settingsHelp =>
      failure.problem == LocationProblem.serviceDisabled ||
      failure.problem == LocationProblem.permissionDeniedForever;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_disabled, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location unavailable',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          Text(failure.message, style: const TextStyle(fontSize: 13)),
          if (_settingsHelp) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Open settings'),
            ),
          ],
        ],
      ),
    );
  }
}
