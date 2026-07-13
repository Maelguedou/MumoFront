import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';
import 'Agent_accueil_page.dart';
import 'Agent_historique_page.dart';
import 'Agent_profile_page.dart';

class AgentmainscreenPage extends ConsumerStatefulWidget {
  const AgentmainscreenPage({super.key});

  @override
  ConsumerState<AgentmainscreenPage> createState() =>
      _AgentmainscreenPageState();
}

class _AgentmainscreenPageState extends ConsumerState<AgentmainscreenPage> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    Center(
      child: AgentAccueilPage(
        onViewHistory: () => setState(() => _selectedIndex = 1),
      ),
    ),
    const Center(child: HistoryScreen()),
    const Center(child: Text('Stats')),
    const Center(child: Text('Insights')),
    const AgentProfilePage(),
  ];

  // Fonction pour générer l'icône avec le point rouge en dessous
  Widget _buildActiveIcon(IconData icon) {
    final colors = AppThemeColors(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(height: 4),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colors.isDark
            ? const Color(0xFF0A0A0A)
            : AppColors.surface,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textTertiary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0, // Pour un look plus flat comme sur ta capture
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: _buildActiveIcon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notes),
            activeIcon: _buildActiveIcon(Icons.notes),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.adjust), // Icône style "cible" de ton design
            activeIcon: _buildActiveIcon(Icons.adjust),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            activeIcon: _buildActiveIcon(Icons.auto_awesome),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            activeIcon: _buildActiveIcon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
