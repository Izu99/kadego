import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colours picked from the Figma file.
class C {
  static const orange = Color(0xFFFF6B00);
  static const orangeSoft = Color(0xFFFFF1E6); // selected cards, banners
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6E6E73);
  static const faint = Color(0xFFA1A1A6);
  static const surface = Color(0xFFF4F4F6); // grey fields / cards
  static const line = Color(0xFFE8E8EC);
  static const green = Color(0xFF1E9E52);
  static const greenSoft = Color(0xFFE6F6EC);
  static const amber = Color(0xFFF0A500);
  static const amberSoft = Color(0xFFFFF5DD);
  static const red = Color(0xFFE5484D);
  static const redSoft = Color(0xFFFDECEC);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: C.orange, primary: C.orange, surface: Colors.white),
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: C.ink),
  );
}

TextStyle t(double size, {FontWeight w = FontWeight.w400, Color c = C.ink, double? h}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: h);

String rs(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'Rs. $b';
}
