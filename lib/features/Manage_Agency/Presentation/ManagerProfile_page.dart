import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../Auth/Controller/login_controller.dart';
import '../Controller/agency_check_controller.dart';
import '../Controller/service_point_controller.dart';
import '../domain/entities/service_point.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authNotifier = ref.read(authControllerProvider.notifier);
        authNotifier.ensureUserLoaded().then((_) async {
          final user = ref.read(authControllerProvider).user;
          final hasName =
              (user?.lastname != null && user!.lastname!.isNotEmpty) ||
              (user?.name != null && user!.name!.isNotEmpty);
          if (!hasName) {
            await authNotifier.fetchCurrentUser();
          }
          await ref
              .read(servicePointControllerProvider.notifier)
              .fetchServicePoints();
          await ref.read(agencyCheckControllerProvider.notifier).checkAgency();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final agencyState = ref.watch(agencyCheckControllerProvider);
    final servicePointState = ref.watch(servicePointControllerProvider);
    final currentUser = authState.user;
    final displayName = _displayName(currentUser);
    final initials = _initials(displayName);
    final subtitle = _profileSubtitle(
      role: currentUser?.role,
      userId: currentUser?.id,
      agencyName: agencyState.agency?.name,
      servicePoints: servicePointState.servicePoints,
    );
    final showActiveBadge = _shouldShowActiveBadge(
      role: currentUser?.role,
      agency: agencyState.agency,
    );
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
       appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        centerTitle: true,
        titleSpacing: 20,
        title: Text(
          'Profil',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 8),
        ),
        shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              // --- EN-TÊTE DE PROFIL (Nouvelle partie) ---
              _buildProfileHeader(
                displayName: displayName,
                initials: initials,
                subtitle: subtitle,
                showActiveBadge: showActiveBadge,
              ),

              const SizedBox(height: 35),

              // --- GROUPE DES RÉGLAGES ---
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.info_outline,
                      title: "Informations personnelles",
                      subtitle: "Nom,prénom,téléphone,email",
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _buildDivider(),
                    _buildSettingItem(
                      icon: Icons.shield_outlined,
                      title: "Sécurité & PIN",
                      subtitle: "Code PIN, authentification",
                      onTap: () => context.push('/edit-security'),
                    ),
                    _buildDivider(),
                    _buildSettingItem(
                      icon: Icons.dark_mode_outlined,
                      title: "Dark mode",
                      subtitle: isDarkMode
                          ? "Mode sombre activé"
                          : "Mode clair activé",
                      trailing: Switch(
                        value: isDarkMode,
                        activeThumbColor: colors.primary,
                        activeTrackColor: colors.primarySoftBorder,
                        inactiveThumbColor: AppColors.textTertiary,
                        inactiveTrackColor: colors.surfaceAlt,
                        onChanged: (value) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingItem(
                      icon: Icons.help_outline,
                      title: "Aide & support",
                      subtitle: "FAQ, contact, tutoriels",
                    ),
                    _buildDivider(),
                    _buildSettingItem(
                      icon: Icons.bug_report_outlined,
                      title: "Logs de test",
                      subtitle: "Copier les logs pour le diagnostic",
                      onTap: () => context.push('/debug-logs'),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- BANNIÈRE PREMIUM ---
              _buildPremiumBanner(),

              const SizedBox(height: 20),

              // --- BOUTON DÉCONNEXION ---
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader({
    required String displayName,
    required String initials,
    required String subtitle,
    required bool showActiveBadge,
  }) {
    final colors = AppThemeColors(context);

    return Column(
      children: [
        // Utilisation d'un Stack pour superposer le point vert
        Stack(
          children: [
            // L'avatar principal
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFD3101D),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Le point vert en bas à droite
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32), // Vert de l'image
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Nom de l'agent
        Text(
          displayName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 5),
        if (showActiveBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: colors.successBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Actif",
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
  // ... (Garder les méthodes _buildSettingItem, _buildDivider, etc. de la réponse précédente)

  Widget _buildPremiumBanner() {
    final colors = AppThemeColors(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.goldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.isDark
              ? const Color(0xFF5C4508)
              : const Color(0xFFFFE5A0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.star, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Passer en Premium",
                  style: TextStyle(
                    color: colors.isDark
                        ? const Color(0xFFFACC15)
                        : const Color(0xFF5C3D00),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  "Insights IA · Multi-cabines illimités",
                  style: TextStyle(
                    color: colors.isDark
                        ? const Color(0xFFD6B85A)
                        : const Color(0x995C3D00),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFF5A623)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final colors = AppThemeColors(context);

    return TextButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final dialogColors = AppThemeColors(ctx);
            return AlertDialog(
              backgroundColor: dialogColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: dialogColors.border),
              ),
              title: Text(
                'Confirmer la déconnexion',
                style: TextStyle(
                  fontSize: 18,
                  color: dialogColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Voulez-vous vous déconnecter ?',
                style: TextStyle(color: dialogColors.textSecondary),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: dialogColors.surfaceAlt,
                        foregroundColor: dialogColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: dialogColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
        if (confirm == true) {
          await ref.read(authControllerProvider.notifier).logout();
          if (mounted) context.go('/login');
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: colors.surfaceElevated,
        foregroundColor: colors.primary,
        overlayColor: colors.primarySoft,
        minimumSize: const Size(double.infinity, 67),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 20),
          SizedBox(width: 8),
          Text(
            "Se déconnecter",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    final colors = AppThemeColors(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
    );
  }

  Widget _buildDivider() => Divider(
    height: 1,
    indent: 70,
    endIndent: 20,
    color: AppThemeColors(context).border,
  );

  String _displayName(dynamic user) {
    final name = user?.name?.toString().trim();
    final lastname = user?.lastname?.toString().trim();

    final parts = [
      name,
      lastname,
    ].where((part) => part != null && part.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return 'Utilisateur';
  }

  String _profileSubtitle({
    required String? role,
    required String? userId,
    required String? agencyName,
    required List<ServicePoint> servicePoints,
  }) {
    final normalizedRole = role?.trim().toLowerCase();
    final effectiveAgencyName = agencyName?.trim();
    final cabinName = _findCabinNameForUser(servicePoints, userId)?.trim();

    final isUserRole = normalizedRole == 'user' || normalizedRole == 'agent';
    if (!isUserRole) {
      return (effectiveAgencyName != null && effectiveAgencyName.isNotEmpty)
          ? effectiveAgencyName
          : 'Agence';
    }

    final parts = <String>[];
    if (cabinName != null && cabinName.isNotEmpty) {
      parts.add(cabinName);
    }
    if (effectiveAgencyName != null && effectiveAgencyName.isNotEmpty) {
      parts.add(effectiveAgencyName);
    }

    if (parts.isNotEmpty) {
      return parts.join(' — ');
    }

    return effectiveAgencyName ?? 'Cabine';
  }

  String? _findCabinNameForUser(
    List<ServicePoint> servicePoints,
    String? userId,
  ) {
    if (servicePoints.isEmpty) {
      return null;
    }

    if (userId != null && userId.isNotEmpty) {
      for (final item in servicePoints) {
        if (item.userId == userId) {
          return item.name;
        }
      }
    }

    return servicePoints.first.name;
  }

  bool _shouldShowActiveBadge({
    required String? role,
    required dynamic agency,
  }) {
    final normalizedRole = role?.trim().toLowerCase();
    final isAdmin = normalizedRole == 'admin';
    if (!isAdmin) {
      return true;
    }

    final agencyObject = agency;
    final isDeleted = agencyObject != null && agencyObject.isDeleted == true;
    return agencyObject != null && !isDeleted;
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      final single = parts.first;
      if (single.length >= 2) {
        return single.substring(0, 2).toUpperCase();
      }
      return single.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
