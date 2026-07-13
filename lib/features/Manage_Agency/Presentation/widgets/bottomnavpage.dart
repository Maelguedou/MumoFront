import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';

class MumoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MumoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Cabines'),
      (Icons.show_chart_outlined, Icons.show_chart_rounded, 'Stats'),
      (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Insights'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF0A0A0A) : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.transparent : const Color(0x0F000000),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: colors.isDark
                ? AppColors.blackBorder
                : const Color(0x0A000000),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              final item = items[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicateur en haut — s'étire quand actif
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        height: 2.5,
                        width: isActive ? 28.0 : 0.0,
                        decoration: BoxDecoration(
                          color: AppColors.primary, // #D0021B
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive ? item.$2 : item.$1,
                          key: ValueKey(isActive),
                          size: 22,
                          color: isActive
                              ? colors.primary
                              : colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? colors.primary
                              : colors.textTertiary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
