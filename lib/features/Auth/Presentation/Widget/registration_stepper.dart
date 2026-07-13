import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';

class RegistrationStepper extends StatelessWidget {
  final int currentStep;
  static const Color mumoRed = Color(0xFFC70025);

  const RegistrationStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton Retour et Stepper
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                if (currentStep > 1) {
                  context.go('/register');
                }
              },
              child: Row(
                children: [
                  Icon(Icons.arrow_back, size: 20, color: colors.textPrimary),
                  const SizedBox(width: 5),
                  Text(
                    "Retour",
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Les cercles d'étapes
            _buildStepCircle(
              context,
              1,
              isCompleted: currentStep > 1,
              isActive: currentStep == 1,
            ),
            _buildLine(context, isActive: currentStep > 1),
            _buildStepCircle(
              context,
              2,
              isCompleted: false,
              isActive: currentStep == 2,
            ),
          ],
        ),
        const SizedBox(height: 30),
        // Titre dynamique selon l'étape
        Text(
          currentStep == 1 ? "Inscription" : "Sécurité",
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          currentStep == 1
              ? "Étape 1 sur 2 : Vos informations"
              : "Étape 2 sur 2 : Finalisez votre compte",
          style: TextStyle(color: colors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStepCircle(
    BuildContext context,
    int step, {
    bool isCompleted = false,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    final colors = AppThemeColors(context);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive ? colors.primary : colors.surfaceAlt,
        border: isDisabled ? Border.all(color: colors.border) : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                "$step",
                style: TextStyle(
                  color: isCompleted || isActive
                      ? Colors.white
                      : colors.textTertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildLine(BuildContext context, {bool isActive = false}) {
    final colors = AppThemeColors(context);
    return Container(
      width: 20,
      height: 2,
      color: isActive ? colors.primary : colors.border,
    );
  }
}
