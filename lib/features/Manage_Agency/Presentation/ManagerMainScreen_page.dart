import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ManagerDashboardpage.dart';
import 'ManagerInsightspage.dart';
import 'ManagerCabine_page.dart';
import 'ManagerStats_page.dart';
import 'ManagerProfile_page.dart';
import '../../../core/theme/app_theme_colors.dart';
import 'widgets/bottomnavpage.dart';

class ManagerMainScreen extends ConsumerStatefulWidget {
  const ManagerMainScreen({super.key});

  @override
  ConsumerState<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends ConsumerState<ManagerMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const CabinsPage(),
    const StatsPage(),
    const InsightsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: MumoBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
