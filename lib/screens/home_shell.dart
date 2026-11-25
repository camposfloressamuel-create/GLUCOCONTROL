import 'package:flutter/material.dart';

import 'add_glucose_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openAddGlucose() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddGlucoseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onNavigateTab: _navigateToTab,
        onAddGlucose: _openAddGlucose,
      ),
      const HistoryScreen(),
      const StatisticsScreen(),
      const RemindersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton.extended(
              onPressed: _openAddGlucose,
              icon: const Icon(Icons.add_rounded, size: 28),
              label: const Text(
                'Registrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _navigateToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Gráficas',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
