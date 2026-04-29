import 'package:flutter/material.dart';

class AppColors {
  // Palette diambil dari logo Monoframe:
  // biru muda sebagai brand surface, biru tua sebagai teks/aksi, putih sebagai logo.
  static const Color logoBlue = Color(0xFFA8CBE0);
  static const Color primary = Color(0xFF6F9FBE);
  static const Color primaryDark = Color(0xFF29475F);
  static const Color primaryLight = Color(0xFFA7C9DC);
  static const Color primarySoft = Color(0xFFEAF5FA);

  static const Color secondary = Color(0xFFF5F8FB);
  static const Color accent = Color(0xFF88B9D1);

  static const Color dark = Color(0xFF1F2937);
  static const Color light = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF8A95A3);
  static const Color lightGrey = Color(0xFFF4F7FA);
  static const Color border = Color(0xFFE5EDF3);

  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  static const Color background = Color(0xFFF7FBFD);
  static const Color white = Colors.white;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient darkBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );
}
