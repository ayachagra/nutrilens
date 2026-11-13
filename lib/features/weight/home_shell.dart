import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'activity_screen.dart';
import 'coach_screen.dart';
import 'goal_screen.dart';
import 'nutrition_screen.dart';
import 'weight_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    WeightScreen(),
    NutritionScreen(),
    GoalScreen(),
    ActivityScreen(),
    CoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (_index != i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale),
            label: 'Poids',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Objectifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Activité',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Coach',
          ),
        ],
      ),
    );
  }
}
