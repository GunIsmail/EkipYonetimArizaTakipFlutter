// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- ANA RENK PALETİ (Sabit Renkler) ---
  // Bu renkler moddan bağımsız markamızın renkleridir
  static const Color _brandPurple = Color(0xFF6C63FF);
  static const Color _brandDarkPurple = Color(0xFF4B45B2);
  static const Color _brandGreen = Color(0xFF10B981);
  static const Color _brandRed = Color(0xFFEF4444);
  static const Color _brandOrange = Color(0xFFF59E0B);

  // --- AYDINLIK MOD (Light Theme) RENKLERİ ---
  static const Color primary = _brandPurple;
  static const Color secondary = _brandDarkPurple;
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF9FAFB); // Hafif gri
  static const Color textPrimary = Color(0xFF111827); // Koyu gri
  static const Color textSecondary = Color(0xFF6B7280); // Gri

  // --- KARANLIK MOD (Dark Theme) RENKLERİ ---
  // İleride Dark Mode açıldığında bu renkler devreye girecek
  static const Color primaryDark = Color(
    0xFF818CF8,
  ); // Koyu modda morun daha açık tonu okunur
  static const Color backgroundDark = Color(
    0xFF121212,
  ); // Tam siyah değil, göz yormayan koyu gri
  static const Color surfaceDark = Color(0xFF1E1E1E); // Kartların rengi
  static const Color textPrimaryDark = Color(0xFFE0E0E0); // Beyaza yakın gri
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // Daha koyu gri

  // --- DURUM RENKLERİ ---
  static const Color success = _brandGreen;
  static const Color error = _brandRed;
  static const Color warning = _brandOrange;
}
