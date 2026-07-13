import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../data/onboarding_model.dart';

class OnboardingBody extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingBody({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight( 
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return RadialGradient(
                            radius: 0.55,
                            colors: [
                              Colors.white,       
                              Colors.white, 
                              Colors.transparent, 
                            ],
                            stops: const [0.0, 0.8, 1.0], 
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn, 
                        child: Image.asset(
                          model.image,
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image, 
                            size: 100, 
                            color: Colors.red
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        model.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        model.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.5),
                      ),
                    ),
                    const Spacer(flex: 2), // Remplacé ton SizedBox(height: 180) par un Spacer dynamique
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}