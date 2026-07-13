import 'package:flutter/material.dart';

class AppColors {
  // ── Primaires ─────────────────────────────────────────────────
  static const Color primary = Color(0xFFD0021B); // Rouge Mumo — CTA, actif
  static const Color primaryDark = Color(0xFF8B0011); // Pour gradients
  static const Color primarySoft = Color(0xFFFFF0F1); // Background rouge léger
  static const Color primarySoftBorder = Color(0xFFFFCDD2);

  // ── Fond & surfaces (light mode) ──────────────────────────────
  static const Color background = Color(0xFFFAFAFA); // Page
  static const Color surface = Color(0xFFFFFFFF); // Cards
  static const Color surfaceAlt = Color(0xFFF2F2F4); // Inputs, secondary zones

  // ── Texte (light mode) ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D0D0D); // Titres, corps principal
  static const Color textSecondary = Color(0xFF555555); // Labels, descriptions
  static const Color textTertiary = Color(
    0xFF9A9A9A,
  ); // Hints, captions, timestamps

  // ── Bordures ──────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color borderMid = Color(0xFFD0D0D0);

  // ── Sémantiques (statuts) ─────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color pending = Color(
    0xFFF97316,
  ); // En attente — DISTINCT du gold
  static const Color pendingBg = Color(0xFFFFF7ED);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // ── Types d'opérations ───────────────────────────────────────
  // Garder ces alias pour assurer une cohérence visuelle partout.
  static const Color operationDeposit = info; // Dépôt — bleu
  static const Color operationWithdrawal = warning; // Retrait — jaune orangé
  static const Color operationTransfer = success; // Transfert — vert

  // ── Premium — or exclusif ─────────────────────────────────────
  // ⚠️ Utiliser UNIQUEMENT pour les badges/features Premium
  // Ne jamais utiliser pour les statuts "en attente"
  static const Color gold = Color(0xFFF5A623);
  static const Color goldBg = Color(0xFFFFFBEB);

  // ── Dark mode ─────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceAlt = Color(0xFF242424);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFABABAB);
  static const Color darkTextTertiary = Color(0xFF6B6B6B);
  static const Color darkBorder = Color(0x12FFFFFF);

  // ── Black mode premium ────────────────────────────────────────
  static const Color blackBackground = Color(0xFF050505);
  static const Color blackSurface = Color(0xFF101010);
  static const Color blackSurfaceElevated = Color(0xFF171717);
  static const Color blackSurfaceAlt = Color(0xFF202020);
  static const Color blackPressed = Color(0xFF292929);
  static const Color blackBorder = Color(0xFF2A2A2A);

  static const Color blackTextPrimary = Color(0xFFF5F5F5);
  static const Color blackTextSecondary = Color(0xFFB8B8B8);
  static const Color blackTextTertiary = Color(0xFF777777);
  static const Color blackTextDisabled = Color(0xFF555555);

  static const Color primaryDarkMode = Color(0xFFE0142A);
  static const Color primarySoftDark = Color(0xFF2A070C);
  static const Color primarySoftBorderDark = Color(0xFF5A111B);

  static const Color successBgDark = Color(0xFF0B2A17);
  static const Color pendingBgDark = Color(0xFF2C1A06);
  static const Color errorBgDark = Color(0xFF2A0C0C);
  static const Color infoBgDark = Color(0xFF0B1D33);
  static const Color warningBgDark = Color(0xFF2A2108);

  static const Color mtnBgDark = Color(0xFF352A06);
  static const Color mtnFgDark = Color(0xFFFACC15);
  static const Color moovBgDark = Color(0xFF351A08);
  static const Color moovFgDark = Color(0xFFFB923C);
  static const Color celtiisBgDark = Color(0xFF102515);
  static const Color celtiisFgDark = Color(0xFF9AD66A);
}
