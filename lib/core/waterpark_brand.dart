import 'package:flutter/material.dart';

class WaterparkBrand {
  const WaterparkBrand._();

  static const primaryBlue = Color(0xFF0077C8);
  static const secondaryBlue = Color(0xFF4CB6F5);
  static const lightBlue = Color(0xFFEAF6FF);
  static const accentRed = Color(0xFFE53935);
  static const deepBlue = Color(0xFF002B45);
  static const aqua = Color(0xFF00B8A9);
  static const success = Color(0xFF28A745);
  static const warning = Color(0xFFFFB020);
  static const gray = Color(0xFF9AA4B2);
  static const surface = Colors.white;
  static const background = Color(0xFFF4FAFF);

  static const oceanGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, secondaryBlue],
  );

  static const waveGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [aqua, primaryBlue],
  );
}
