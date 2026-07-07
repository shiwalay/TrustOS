import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 5-tab shell — Home · Network · ➕ Act · Communities · You
/// (10-ux-design.md §2.1). Each tab keeps its own navigator stack via
/// StatefulShellRoute.indexedStack (09-mobile-architecture.md §5.1).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab pops to its root (platform convention).
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Network',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Act',
          ),
          NavigationDestination(
            icon: Icon(Icons.diversity_3_outlined),
            selectedIcon: Icon(Icons.diversity_3),
            label: 'Communities',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
