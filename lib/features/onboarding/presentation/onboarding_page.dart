import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../data/onboarding_model.dart';
import 'widgets/onboarding_body.dart';
import '../controller/onboarding_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final OnboardingController _logic = OnboardingController();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    // ListenableBuilder écoute _logic. Quand _logic fait notifyListeners(),
    // TOUT ce qui est à l'intérieur du builder se rafraîchit.
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            surfaceTintColor: colors.background,
            elevation: 0,
            leadingWidth: 150,
            leading: _buildLogo(),
            actions: [_buildBackBtn()],
          ),
          body: Stack(
            children: [
              PageView.builder(
                controller: _logic.pageController,
                onPageChanged: _logic.onPageChanged,
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) {
                  return OnboardingBody(model: onboardingPages[index]);
                },
              ),

              // 2. L'indicateur et le bouton (Section du bas)
              Positioned(
                bottom: 30,
                left: 28,
                right: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- LES POINTS (Dots) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(onboardingPages.length, (index) {
                        // ON UTILISE _logic.currentPage ICI
                        final bool isSelected = _logic.currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isSelected ? 24 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary
                                : colors.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // --- LE BOUTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        // ON APPELLE LA LOGIQUE DU CONTROLLER
                        onPressed: () => _logic.handleNext(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD30022),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _logic.currentPage == onboardingPages.length - 1
                                  ? "Commencer"
                                  : "Suivant",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_logic.currentPage ==
                                onboardingPages.length - 1) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.rocket_launch,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PETITS WIDGETS D'APPBAR EXTRAITS ---
  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD30022),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'Mumo',
                  style: TextStyle(color: AppThemeColors(context).textPrimary),
                ),
                TextSpan(
                  text: 'Agent',
                  style: TextStyle(color: AppThemeColors(context).primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackBtn() {
    final colors = AppThemeColors(context);

    // On ne l'affiche que si on n'est pas sur la première page
    if (_logic.currentPage == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: Center(
        child: InkWell(
          onTap: () => _logic.handlePrevious(
            context,
          ), // Appelle la fonction du controller
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  size: 12,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Retour',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
