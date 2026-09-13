/// Thème « Émeraude & Or » — charte visuelle AGBE Family.
///
/// Palette dérivée du design system web (PGF) :
///   - cuir émeraude profond #0D4D3B (emblème AGBETOSSOU)
///   - émeraude principal     #0D5C46
///   - or des reliefs         #D4AF37 / #996515
library;

import 'package:flutter/material.dart';

abstract final class AgbeCouleurs {
  static const Color emeraudeProfond = Color(0xFF0D4D3B);
  static const Color emeraude = Color(0xFF0D5C46);
  static const Color emeraudeClair = Color(0xE6116B50);
  static const Color or = Color(0xFFD4AF37);
  static const Color orFonce = Color(0xFF996515);
  static const Color ivoire = Color(0xFFFDFCF7);
  static const Color ardoise = Color(0xFF33413B);
}

/// Dégradé « forêt & or » — bandeaux hero (connexion, en-têtes).
const LinearGradient degradeEmeraude = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0D4D3B), Color(0xFF116B50), Color(0xFF15745A)],
);

ThemeData agbeThemeClair() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AgbeCouleurs.emeraude,
    brightness: Brightness.light,
    primary: AgbeCouleurs.emeraude,
    secondary: AgbeCouleurs.orFonce,
    tertiary: AgbeCouleurs.or,
    surface: Colors.white,
    surfaceContainerHighest: const Color(0xFFEDF3F0),
    error: const Color(0xFFB3261E),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AgbeCouleurs.ivoire,
    fontFamily: null, // police système — sobriété et robustesse hors-ligne
    appBarTheme: AppBarTheme(
      backgroundColor: AgbeCouleurs.emeraudeProfond,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Colors.white,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: Color(0x140D4D3B)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AgbeCouleurs.emeraude,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AgbeCouleurs.emeraude,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AgbeCouleurs.emeraude, width: 1.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC9D6D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC9D6D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AgbeCouleurs.emeraude, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AgbeCouleurs.ardoise),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0x1F0D5C46),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: const StadiumBorder(),
      backgroundColor: const Color(0xFFEDF3F0),
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE3EBE7), thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AgbeCouleurs.emeraudeProfond,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AgbeCouleurs.emeraude,
    ),
  );

  return base;
}

/// Badge doré (numéro de notifications, KPIs en exergue).
class BadgeOr extends StatelessWidget {
  const BadgeOr({super.key, required this.child, this.min = 0});

  final int min;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AgbeCouleurs.or, AgbeCouleurs.orFonce]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        child: child,
      ),
    );
  }
}
