import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/branch.dart';
import '../../state/employee_providers.dart';
import '../../widgets/async_view.dart';
import 'branch_form_screen.dart';

class BranchesListScreen extends ConsumerWidget {
  const BranchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Branches & Geofence')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const BranchFormScreen(),
        )),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add branch'),
      ),
      body: AsyncView(
        value: branches,
        onRetry: () => ref.invalidate(branchesStreamProvider),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No branches yet.\nAdd a branch to configure its geofence.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _BranchTile(branch: list[i]),
          );
        },
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
        title: Text(branch.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${branch.latitude.toStringAsFixed(5)}, '
          '${branch.longitude.toStringAsFixed(5)}  •  '
          'r = ${branch.radiusMeters.round()} m',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BranchFormScreen(branch: branch),
        )),
      ),
    );
  }
}
