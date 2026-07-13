import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../Controller/agency_register_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';

// --- Le Widget Principal de la Page ---
class CreateAgencyPage extends ConsumerStatefulWidget {
  const CreateAgencyPage({super.key});

  @override
  ConsumerState<CreateAgencyPage> createState() => _CreateAgencyPageState();
}

class _CreateAgencyPageState extends ConsumerState<CreateAgencyPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Clé globale pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(agencyRegisterControllerProvider.notifier).resetStatus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Méthode de validation et de soumission
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final agencyName = _nameController.text;
      final agencyAddress = _addressController.text;

      ref
          .read(agencyRegisterControllerProvider.notifier)
          .createAgency(name: agencyName, location: agencyAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agencyState = ref.watch(agencyRegisterControllerProvider);
    final colors = AppThemeColors(context);

    ref.listen(agencyRegisterControllerProvider, (previous, next) async {
      if (next.isSuccess && previous?.isSuccess != true) {
        if (!mounted) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          const MaterialBanner(
            content: Text("Agence creee avec succes"),
            backgroundColor: AppColors.success,
            contentTextStyle: TextStyle(color: Colors.white),
            actions: [SizedBox.shrink()],
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          messenger.hideCurrentMaterialBanner();
        });
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) {
          return;
        }
        messenger.clearMaterialBanners();
        context.go('/manage-agency');
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: colors.textPrimary,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      'Retour',
                      style: TextStyle(fontSize: 17, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Création d\'Agence',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Informations de l\'agence',
                      style: TextStyle(
                        fontSize: 17,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nom de l\'agence',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCustomTextField(
                        controller: _nameController,
                        hintText: 'Ex: Agence ProImmo',
                        validatorText: 'Veuillez entrer le nom de l\'agence',
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Adresse de l\'agence',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCustomTextField(
                        controller: _addressController,
                        hintText: 'Ex: 12 Rue du Commerce, 75001 Paris',
                        validatorText: 'Veuillez entrer l\'adresse',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: agencyState.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: agencyState.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Créer l\'Agence',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
              if (agencyState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    agencyState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget utilitaire pour construire des champs de texte uniformes ---
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required String validatorText,
    int maxLines = 1,
  }) {
    final colors = AppThemeColors(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 17, color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 17,
          color: colors.textTertiary,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: colors.surfaceAlt,
        // Bordure par défaut (quand non sélectionné)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        // Bordure quand le champ est sélectionné (Focused)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        // Bordure en cas d'erreur de validation
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      // Logique de validation basique
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorText;
        }
        return null;
      },
    );
  }
}
