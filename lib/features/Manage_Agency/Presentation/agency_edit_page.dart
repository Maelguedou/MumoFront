import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../Controller/agency_check_controller.dart';
import '../Controller/agency_edit_controller.dart';

class EditAgencyPage extends ConsumerStatefulWidget {
  const EditAgencyPage({super.key});

  @override
  ConsumerState<EditAgencyPage> createState() => _EditAgencyPageState();
}

class _EditAgencyPageState extends ConsumerState<EditAgencyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(agencyEditControllerProvider.notifier).resetStatus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _fillInitialValues() {
    final agency = ref.read(agencyCheckControllerProvider).agency;
    if (agency == null) return;
    _nameController.text = agency.name ?? '';
    _locationController.text = agency.location ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final agencyState = ref.watch(agencyCheckControllerProvider);
    final editState = ref.watch(agencyEditControllerProvider);
    final agency = agencyState.agency;
    final colors = AppThemeColors(context);

    ref.listen(agencyEditControllerProvider, (previous, next) async {
      if (next.isSuccess && previous?.isSuccess != true) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          const MaterialBanner(
            content: Text('Agence mise a jour avec succes'),
            backgroundColor: AppColors.success,
            contentTextStyle: TextStyle(color: Colors.white),
            actions: [SizedBox.shrink()],
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          messenger.hideCurrentMaterialBanner();
        });
        ref.read(agencyCheckControllerProvider.notifier).setAgency(next.agency);
        await Future.delayed(const Duration(milliseconds: 250));
        if (context.mounted) {
          context.pop();
        }
      }
    });

    if (!_isInitialized && agency != null) {
      _isInitialized = true;
      _fillInitialValues();
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          'Modifier l\'agence',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations de l\'agence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifie uniquement le nom et l\'adresse de l\'agence.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildField(
                  label: 'Nom de l\'agence',
                  controller: _nameController,
                  hint: 'Ex: Agence ProImmo',
                ),
                const SizedBox(height: 20),
                _buildField(
                  label: 'Adresse de l\'agence',
                  controller: _locationController,
                  hint: 'Ex: 12 Rue du Commerce, 75001 Paris',
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: editState.isLoading
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
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: editState.isLoading || agency == null
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
                          child: editState.isLoading
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
                if (editState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    editState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (agency == null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Aucune agence n\'a été trouvée pour cet utilisateur.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final agencyId = ref.read(agencyCheckControllerProvider).agency?.id;
    if (agencyId == null || agencyId.isEmpty) {
      return;
    }
    ref
        .read(agencyEditControllerProvider.notifier)
        .updateAgency(
          id: agencyId,
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
        );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
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
