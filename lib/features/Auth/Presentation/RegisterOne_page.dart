import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_colors.dart';
import 'Widget/registration_stepper.dart';
import '../di/register_providers.dart';

class RegisterStepOne extends ConsumerStatefulWidget {
  const RegisterStepOne({super.key});

  @override
  ConsumerState<RegisterStepOne> createState() => _RegisterStepOneState();
}

class _RegisterStepOneState extends ConsumerState<RegisterStepOne> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  static const Color mumoRed = Color(0xFFC70025);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(registerDraftProvider);
    _nameController.text = draft.firstName;
    _lastNameController.text = draft.lastName;
    _emailController.text = draft.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

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
                RegistrationStepper(currentStep: 1),
                const SizedBox(height: 40),

                _buildInputLabel("Prénom"),
                _buildTextField(
                  _nameController,
                  "Ex: Dossou",
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Nom"),
                _buildTextField(
                  _lastNameController,
                  "Ex: AGBO",
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Adresse Email"),
                _buildTextField(
                  _emailController,
                  "dossou.agbo@gmail.com",
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _submitStepOne,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mumoRed,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Continuer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Deja un compte ? ",
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        "Se connecter",
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitStepOne() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(registerDraftProvider.notifier);
    notifier.setFirstName(_nameController.text);
    notifier.setLastName(_lastNameController.text);
    notifier.setEmail(_emailController.text);

    context.go('/register2');
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Champ obligatoire";
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return "Champ obligatoire";
    }
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegex.hasMatch(trimmed)) {
      return "Email invalide";
    }
    return null;
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(height: 25),
        const Text(
          "Inscription",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const Text(
          "Étape 1 sur 2 : Vos informations",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppThemeColors(context).textPrimary,
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colors = AppThemeColors(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colors.surfaceAlt,
        hintStyle: TextStyle(color: colors.textTertiary),
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
      ),
    );
  }
}
