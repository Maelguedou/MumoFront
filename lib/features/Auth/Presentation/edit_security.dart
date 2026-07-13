import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../Controller/login_controller.dart';

class EditSecurityPage extends ConsumerStatefulWidget {
  const EditSecurityPage({super.key});

  @override
  ConsumerState<EditSecurityPage> createState() => _EditSecurityPageState();
}

class _EditSecurityPageState extends ConsumerState<EditSecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _CurrentPasswordController = TextEditingController();
  final _NewPasswordController = TextEditingController();
  final _ConfirmPasswordController = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).resetStatus();
    });
  }

  @override
  void dispose() {
    _CurrentPasswordController.dispose();
    _NewPasswordController.dispose();
    _ConfirmPasswordController.dispose();
    super.dispose();
  }

  void _fillInitialValues() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    _CurrentPasswordController.text = '';
    _NewPasswordController.text = '';
    _ConfirmPasswordController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final colors = AppThemeColors(context);

    ref.listen(authControllerProvider, (previous, next) async {
      if (next.isSuccess && previous?.isSuccess != true) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          const MaterialBanner(
            content: Text('Mot de passe mis à jour avec succès'),
            backgroundColor: AppColors.success,
            contentTextStyle: TextStyle(color: Colors.white),
            actions: [SizedBox.shrink()],
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          messenger.hideCurrentMaterialBanner();
        });
        if (context.mounted) {
          final wasForced = previous?.user?.mustChangePassword ?? false;
          if (wasForced) {
            final contexts = next.user?.contexts.isNotEmpty == true
                ? next.user!.contexts
                : previous?.user?.contexts ?? const [];

            if (contexts.length > 1) {
              context.go('/choose-workspace');
              return;
            }

            if (contexts.length == 1) {
              final selectedContext = contexts.first;
              await ref
                  .read(authControllerProvider.notifier)
                  .selectContext(selectedContext);
              if (!context.mounted) return;

              if (selectedContext.isAgent) {
                context.go('/agent-home');
              } else if (selectedContext.isManager) {
                context.go('/manage-agency');
              } else {
                context.go('/agent-home');
              }
              return;
            }

            final role = next.user?.role?.toLowerCase();
            if (role == 'agent' || role == 'user') {
              context.go('/agent-home');
            } else {
              context.go('/manage-agency');
            }
          } else {
            context.pop();
          }
        }
      }
    });

    if (!_isInitialized && user != null) {
      _isInitialized = true;
      _fillInitialValues();
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: user?.mustChangePassword == true
            ? false
            : true,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          'Sécurité & PIN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      body: SafeArea(
        child: PopScope(
          canPop: user?.mustChangePassword == true ? false : true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mot de passe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.mustChangePassword == true
                        ? 'Vôtre première connexion. Changez vôtre mot de passe pour continuer.'
                        : 'Mettez à jour vôtre mot de passe.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildField(
                    label: 'Mot de passe actuel',
                    controller: _CurrentPasswordController,
                    hint: 'Vôtre mot de passe actuel',
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'Nouveau mot de passe',
                    controller: _NewPasswordController,
                    hint: 'Nouveau mot de passe',
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'Confirmer le mot de passe',
                    controller: _ConfirmPasswordController,
                    hint: 'Confirmer le mot de passe',
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (user?.mustChangePassword != true) ...[
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textPrimary,
                                side: BorderSide(color: colors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Annuler',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authState.isLoading || user == null
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enregistrer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        authState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          currentPassword: _CurrentPasswordController.text.trim(),
          password: _NewPasswordController.text.trim(),
          passwordConfirmation: _ConfirmPasswordController.text.trim(),
        );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    required bool obscureText,
  }) {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
