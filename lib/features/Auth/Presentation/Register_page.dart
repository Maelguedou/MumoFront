import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'Widget/registration_stepper.dart';
import '../Controller/Register_controller.dart';
import '../di/register_providers.dart';
import '../../../core/theme/app_theme_colors.dart';

class RegisterStepTwoPage extends ConsumerStatefulWidget {
  const RegisterStepTwoPage({super.key});

  @override
  ConsumerState<RegisterStepTwoPage> createState() =>
      _RegisterStepTwoPageState();
}

class _RegisterStepTwoPageState extends ConsumerState<RegisterStepTwoPage> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _npiController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const Color mumoRed = Color(0xFFC70025);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(registerDraftProvider);
    _phoneController.text = draft.phone;
    _npiController.text = draft.npi;
    _passwordController.text = draft.password;
    _confirmPasswordController.text = draft.confirmPassword;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _npiController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    final hasConnection = await _hasConnection();
    if (!hasConnection) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearMaterialBanners();
      messenger.showMaterialBanner(
        const MaterialBanner(
          content: Text(
            "Pas de connexion internet. Veuillez réessayer plus tard.",
          ),
          backgroundColor: Color(0xFFFDECEA),
          contentTextStyle: TextStyle(color: Color(0xFFB71C1C)),
          actions: [SizedBox.shrink()],
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        messenger.hideCurrentMaterialBanner();
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(registerDraftProvider.notifier);
      notifier.setPhone(_phoneController.text);
      notifier.setNpi(_npiController.text);
      notifier.setPassword(_passwordController.text);
      notifier.setConfirmPassword(_confirmPasswordController.text);

      final draft = ref.read(registerDraftProvider);

      ref
          .read(registerControllerProvider.notifier)
          .register(
            firstName: draft.firstName,
            lastName: draft.lastName,
            email: draft.email,
            phone: draft.phone,
            npi: draft.npi,
            password: draft.password,
            passwordConfirmation: draft.confirmPassword,
          );
    }
  }

  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(registerControllerProvider);
    final colors = AppThemeColors(context);

    ref.listen(registerControllerProvider, (previous, next) async {
      if (next.isSuccess && previous?.isSuccess != true) {
        if (!mounted) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          const MaterialBanner(
            content: Text("Inscription reussie"),
            backgroundColor: Color(0xFF22C55E),
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
        context.go('/create-agency');
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegistrationStepper(currentStep: 2),
                const SizedBox(height: 40),

                _buildInputLabel("Numéro de téléphone"),
                _buildTextField(
                  controller: _phoneController,
                  hint: "+2290196457812",
                  keyboardType: TextInputType.phone,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Numéro NPI"),
                _buildTextField(
                  controller: _npiController,
                  hint: "129964578120",
                  keyboardType: TextInputType.number,
                  validator: _npiValidator,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Mot de passe"),
                _buildTextField(
                  controller: _passwordController,
                  hint: "••••••••••••",
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Confirmer le mot de passe"),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: "••••••••••••",
                  isPassword: true,
                  obscureText: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (value) {
                    final base = _passwordValidator(value);
                    if (base != null) {
                      return base;
                    }
                    if (value != _passwordController.text) {
                      return "Les mots de passe ne correspondent pas";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mumoRed,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
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
                          "S'inscrire",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),

                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      authState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go('/register');
                    },
                    child: Text(
                      "Retour à l'étape précédente",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPOSANTS UI RÉUTILISABLES ---

  Widget _buildHeader() {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, size: 20, color: colors.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(height: 25),
        const Text(
          "Sécurité",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const Text(
          "Étape 2 sur 2 : Finalisez votre compte",
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    final colors = AppThemeColors(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    final colors = AppThemeColors(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator:
          validator ?? (value) => value!.isEmpty ? "Champ obligatoire" : null,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary),
        filled: true,
        fillColor: colors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: colors.textTertiary,
                ),
                onPressed: onToggle,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Champ obligatoire";
    }
    return null;
  }

  String? _npiValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return "Champ obligatoire";
    }
    if (trimmed.length != 12) {
      return "Le NPI doit contenir 12 chiffres";
    }
    final digitsOnly = RegExp(r"^[0-9]+$");
    if (!digitsOnly.hasMatch(trimmed)) {
      return "Le NPI doit contenir uniquement des chiffres";
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Champ obligatoire";
    }
    if (value.length < 8) {
      return "Le mot de passe doit avoir au moins 8 caracteres";
    }
    return null;
  }
}
