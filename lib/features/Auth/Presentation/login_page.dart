import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../Controller/login_controller.dart';
import '../data/login_state_model.dart';
import '../../Manage_Agency/Controller/agency_check_controller.dart';
import '../../../core/theme/app_theme_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  static const Color mumoRed = Color(0xFFC70025);
  static const Set<String> _managerRoles = {'admin'};

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Utilise authControllerProvider comme défini dans le controller
      ref
          .read(authControllerProvider.notifier)
          .login(_phoneController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // On écoute l'état via authControllerProvider
    final authState = ref.watch(authControllerProvider);
    final colors = AppThemeColors(context);

    ref.listen<AuthStateModel>(authControllerProvider, (previous, next) async {
      if (next.isSuccess && previous?.isSuccess != true) {
        if (!mounted) {
          return;
        }
        String? role = next.user?.role?.trim().toLowerCase();
        if (role == null || role.isEmpty) {
          await ref.read(authControllerProvider.notifier).fetchCurrentUser();
          if (!mounted) {
            return;
          }
          role = ref
              .read(authControllerProvider)
              .user
              ?.role
              ?.trim()
              .toLowerCase();
        }
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          const MaterialBanner(
            content: Text("Connexion reussie"),
            backgroundColor: Color(0xFF22C55E),
            contentTextStyle: TextStyle(color: Colors.white),
            actions: [SizedBox.shrink()],
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          messenger.hideCurrentMaterialBanner();
        });

        // Check if user must change password
        if (next.user?.mustChangePassword == true) {
          context.go('/edit-security');
          return;
        }

        final contexts = next.user?.contexts ?? const [];
        if (contexts.length > 1) {
          context.go('/choose-workspace');
          return;
        }

        if (contexts.length == 1) {
          await ref
              .read(authControllerProvider.notifier)
              .selectContext(contexts.first);
          if (!mounted) {
            return;
          }
          role = contexts.first.role?.trim().toLowerCase();
        }

        final hasKnownRole = role != null && role.isNotEmpty;
        final isAgent = role == 'agent' || role == 'user';
        final isManager = role != null && _managerRoles.contains(role);

        if (isAgent) {
          context.go('/agent-home');
          return;
        }

        if (!hasKnownRole) {
          context.go('/choose-workspace');
          return;
        }

        if (!isManager) {
          context.go('/choose-workspace');
          return;
        }

        ref.read(agencyCheckControllerProvider.notifier).checkAgency();
      }
    });

    ref.listen(agencyCheckControllerProvider, (previous, next) {
      if (!next.isChecked || previous?.isChecked == true) {
        return;
      }
      if (!mounted) {
        return;
      }
      final role = ref.read(authControllerProvider).user?.role?.toLowerCase();
      final isManager = role != null && _managerRoles.contains(role);
      final isAgent = role == 'agent' || role == 'user';

      if (next.statusCode == 401) {
        context.go('/login');
        return;
      }

      if (isAgent) {
        context.go('/agent-home');
        return;
      }

      if (next.errorMessage != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          MaterialBanner(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFFDECEA),
            contentTextStyle: const TextStyle(color: Color(0xFFB71C1C)),
            actions: const [SizedBox.shrink()],
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          messenger.hideCurrentMaterialBanner();
        });
        return;
      }

      if (isManager) {
        if (next.hasAgency) {
          context.go('/manage-agency');
        } else {
          context.go('/create-agency');
        }
        return;
      }

      if (next.hasAgency) {
        context.go('/manage-agency');
        return;
      }

      if (next.statusCode == 404) {
        context.go('/create-agency');
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearMaterialBanners();
      messenger.showMaterialBanner(
        const MaterialBanner(
          content: Text(
            'Impossible de determiner votre destination. Reconnectez-vous.',
          ),
          backgroundColor: Color(0xFFFDECEA),
          contentTextStyle: TextStyle(color: Color(0xFFB71C1C)),
          actions: [SizedBox.shrink()],
        ),
      );
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
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 50),

                _buildTextField(
                  label: "Numéro npi",
                  controller: _phoneController,
                  hint: "129964578120",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 25),

                _buildTextField(
                  label: "Mot de passe",
                  controller: _passwordController,
                  hint: "•••••••••••••••••",
                  isPassword: true,
                  obscureText: _obscurePassword,
                  // SYNCHRO : Correction du nom de callback
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),

                const SizedBox(height: 10),
                _buildForgotPassword(),

                // Affichage de l'erreur venant du Controller
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
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

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mumoRed,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
                          "Se connecter",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 30),
                _buildCreateAccountLink(),
                const SizedBox(height: 50),
                _buildSecurityBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPOSANTS UI (Inchangés pour garder ton style) ---

  Widget _buildHeader() {
    final colors = AppThemeColors(context);
    return Column(
      children: [
        const SizedBox(height: 15),
        _buildLogo(),
        const SizedBox(height: 20),
        Text(
          "Connexion",
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Connectez-vous à votre compte",
          style: TextStyle(color: colors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFD30022),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'M',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggle,
  }) {
    final colors = AppThemeColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colors.surfaceAlt,
            hintStyle: TextStyle(color: colors.textTertiary),
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
              borderSide: BorderSide(color: colors.primary, width: 1.4),
            ),
          ),
          validator: (val) => val!.isEmpty ? "Champ obligatoire" : null,
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    final colors = AppThemeColors(context);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          "Mot de passe oublié ?",
          style: TextStyle(color: colors.primary),
        ),
      ),
    );
  }

  Widget _buildCreateAccountLink() {
    final colors = AppThemeColors(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Pas encore de compte ? ",
          style: TextStyle(color: colors.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            context.go('/register');
          },
          child: Text(
            "S'inscrire",
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    final colors = AppThemeColors(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.fingerprint, color: colors.textPrimary, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Connexion sécurisée",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "PIN biométrique disponible",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
