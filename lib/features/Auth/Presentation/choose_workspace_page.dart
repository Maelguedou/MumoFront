import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../Controller/login_controller.dart';
import '../domain/entities/auth_user.dart';

class ChooseWorkspacePage extends ConsumerWidget {
  const ChooseWorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors(context);
    final user = ref.watch(authControllerProvider).user;
    final contexts = user?.contexts ?? const <AuthContext>[];
    final hasWorkspaces = contexts.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        title: Text(
          hasWorkspaces ? 'Choisir un espace' : 'Espace indisponible',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasWorkspaces) ...[
                Text(
                  user?.name == null
                      ? 'Sélectionnez votre espace de travail'
                      : 'Bonjour ${user!.name}, sélectionnez votre espace',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Expanded(
                child: contexts.isEmpty
                    ? _EmptyState(
                        userName: user?.name,
                        onCreateAgency: () => context.push('/create-agency'),
                        onLogout: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      )
                    : ListView.separated(
                        itemCount: contexts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final workspace = contexts[index];
                          return _WorkspaceCard(
                            workspace: workspace,
                            onTap: () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .selectContext(workspace);

                              if (!context.mounted) return;

                              if (workspace.isManager) {
                                context.go('/manage-agency');
                              } else {
                                context.go('/agent-home');
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.workspace, required this.onTap});

  final AuthContext workspace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final isManager = workspace.isManager;
    final title = isManager ? 'Espace Agence' : 'Espace Cabine';
    final subtitle = isManager
        ? (workspace.agencyName ?? 'Agence')
        : (workspace.servicePointName ?? 'Cabine');
    final detail = isManager
        ? 'Gérer les cabines et agents'
        : (workspace.agencyName ?? 'Opérations de cabine');

    return Material(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isManager ? colors.primarySoft : colors.successBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isManager ? Icons.business_rounded : Icons.store_rounded,
                  color: isManager ? colors.primary : AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.userName,
    required this.onCreateAgency,
    required this.onLogout,
  });

  final String? userName;
  final VoidCallback onCreateAgency;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final greeting = userName == null || userName!.trim().isEmpty
        ? 'Bonjour, vous n’avez aucun espace disponible présentement.'
        : 'Bonjour ${userName!.trim()}, vous n’avez aucun espace disponible présentement.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.domain_disabled_rounded,
                color: colors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              greeting,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre accès à une cabine ou à une agence peut être réactivé par un responsable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onCreateAgency,
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Créer une agence'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
