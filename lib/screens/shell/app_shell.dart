import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_nav_bar.dart';
import '../../widgets/offline_banner.dart';

const _items = [
  GlassNavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
  GlassNavItem(Icons.badge_outlined, Icons.badge_rounded, 'Staff'),
  GlassNavItem(Icons.fingerprint, Icons.fingerprint, 'Attendance'),
  GlassNavItem(Icons.groups_outlined, Icons.groups_rounded, 'Leads'),
  GlassNavItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Approvals'),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
