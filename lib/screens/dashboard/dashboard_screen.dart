import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/router.dart';
import '../../models/dashboard_stats.dart';
import '../../state/dashboard_providers.dart';
import '../../widgets/bento_tile.dart';

final _money =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
            children: [
              const _Header(),
              const SizedBox(height: 16),
              const _WeekStrip(),
              const SizedBox(height: 24),
              Text('Today Report',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              stats.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorCard(
                  message: _friendlyError(e),
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
                data: (s) => _Bento(stats: s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('permission-denied')) {
      return 'Permission denied. Check your Firestore security rules.';
    }
    if (text.contains('unavailable') ||
        text.contains('Timeout') ||
        text.contains('UNAVAILABLE')) {
      return 'Cannot reach Firebase. Check your internet connection.';
    }
    if (text.contains('failed-precondition')) {
      return 'A required Firestore index is still building. '
          'Wait a minute and retry.';
    }
    return 'Could not load dashboard data.\n$text';
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, d MMM').format(DateTime.now()),
                  style: const TextStyle(color: Colors.black54)),
              const Text('NEXA Admin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Settings',
          onPressed: () => context.push(Routes.settings),
          icon: const Icon(Icons.person_outline),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(builder: (_) {
              final d = monday.add(Duration(days: i));
              final today = d.day == now.day && d.month == now.month;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: today ? AppColors.ink : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('E').format(d).substring(0, 1),
                        style: TextStyle(
                            fontSize: 12,
                            color: today ? Colors.white70 : Colors.black45)),
                    const SizedBox(height: 4),
                    Text('${d.day}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: today ? Colors.white : AppColors.ink)),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _Bento extends StatelessWidget {
  const _Bento({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final maxLead = stats.leadsByStatus.values
        .fold<int>(0, (m, v) => v > m ? v : m)
        .clamp(1, 1 << 30);

    return Column(
      children: [
        if (stats.isEmpty) const _EmptyHint(),
        SizedBox(
          height: 340,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(
                      height: 128,
                      child: BentoTile(
                        color: AppColors.cream,
                        border: AppColors.creamBorder,
                        onTap: () => context.go(Routes.employees),
                        child: _Stat(
                            label: 'Employees',
                            value: '${stats.employeesTotal}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BentoTile(
                        color: AppColors.lavender,
                        onTap: () => context.go(Routes.attendance),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Present',
                                style: TextStyle(color: Colors.black54)),
                            Expanded(
                              child: Center(
                                child: RingProgress(
                                  value: stats.attendanceRate,
                                  color: AppColors.lavenderAccent,
                                  track: Colors.white,
                                  size: 104,
                                  stroke: 15,
                                  child: Text(
                                    '${(stats.attendanceRate * 100).round()}%',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: BentoTile(
                  color: AppColors.dark,
                  onTap: () => context.go(Routes.approvals),
                  child: _PendingTile(count: stats.pendingApprovals),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: BentoTile(
                  color: AppColors.pink,
                  onTap: () => context.go(Routes.customers),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _IconBadge(
                              icon: Icons.groups_rounded,
                              color: AppColors.pinkAccent),
                          const SizedBox(width: 10),
                          Text('Leads',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Ticks(
                                filled: stats.customersTotal.clamp(0, 30),
                                color: AppColors.pinkAccent),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('${stats.customersTotal} total',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: BentoTile(
                        color: AppColors.peach,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Collections',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_money.format(stats.collectionsToday),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BentoTile(
                        color: AppColors.rose,
                        padding: const EdgeInsets.all(14),
                        onTap: () => context.go(Routes.attendance),
                        child: const Center(
                          child: Text('Test check-in 📍',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: BentoTile(
                  color: AppColors.orchid,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _IconBadge(
                              icon: Icons.local_fire_department_rounded,
                              color: AppColors.orchidAccent),
                          const SizedBox(width: 10),
                          Text('Pipeline',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final s in leadStatuses)
                              Expanded(
                                child: _PipelineBar(
                                  label: s.substring(0, 3),
                                  count: stats.leadsByStatus[s] ?? 0,
                                  fraction:
                                      (stats.leadsByStatus[s] ?? 0) / maxLead,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: BentoTile(
                  color: AppColors.slate,
                  onTap: () => context.go(Routes.attendance),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _IconBadge(
                          icon: Icons.event_busy_rounded,
                          color: AppColors.slateAccent),
                      const Spacer(),
                      Text('${stats.absentToday}',
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w800)),
                      const Text('Absent today',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text('${stats.presentToday} present',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
        ],
      );
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.fact_check_rounded, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Approvals',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('$count pending',
            style: const TextStyle(
                color: AppColors.lime,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: LayoutBuilder(builder: (context, c) {
              const cols = 5;
              const gap = 6.0;
              final cell = (c.maxWidth - gap * (cols - 1)) / cols;
              final rows = ((c.maxHeight + gap) / (cell + gap)).floor();
              final total = cols * rows;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < total; i++)
                    Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: i < count
                            ? AppColors.coral
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: i == count - 1 && count > 0
                            ? Border.all(color: AppColors.ink, width: 2)
                            : null,
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: color),
      );
}

class _Ticks extends StatelessWidget {
  const _Ticks({required this.filled, required this.color});
  final int filled;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 30; i++)
              Container(
                width: 2.5,
                height: i < filled ? 24 : 14,
                decoration: BoxDecoration(
                  color: i < filled ? color : color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      );
}

class _PipelineBar extends StatelessWidget {
  const _PipelineBar(
      {required this.label, required this.count, required this.fraction});
  final String label;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Text('$count',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: count == 0 ? 0.12 : 0.12 + 0.88 * fraction,
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.orchidAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
            'No data yet. Add employees and customers to see live numbers here.'),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => BentoTile(
        color: AppColors.pink,
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppColors.pinkAccent),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}
