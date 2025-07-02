import 'package:flutter/material.dart';

/// Classe qui définit le thème de l'application SABO League
/// Gère les couleurs, styles et thèmes (clair/sombre) de l'application
class AppTheme {
    /// Couleurs principales de l'application
    static const Color navyBlue = Color(0xFF1A365D);
    static const Color skyBlue = Color(0xFFED8936);
    static const Color offWhite = Color(0xFFF7FAFC);
    static const Color slate = Color(0xFF4A5568);

    /// Dégradé utilisé pour les éléments décoratifs
    static const LinearGradient mainGradient = LinearGradient(
        colors: [navyBlue, skyBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
    );

    /// Style de décoration pour les éléments avec effet glassmorphism
    static BoxDecoration glassBoxDecoration = BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: Offset(0, 8),
            ),
        ],
        border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
        ),
    );

    /// Configuration du thème clair de l'application
    static ThemeData lightTheme = ThemeData(
        brightness: Brightness.light,
        primaryColor: navyBlue,
        scaffoldBackgroundColor: offWhite,
        appBarTheme: AppBarTheme(
            backgroundColor: navyBlue,
            elevation: 0,
            titleTextStyle: TextStyle(
                color: skyBlue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Montserrat',
            ),
            iconTheme: IconThemeData(color: skyBlue),
        ),
        colorScheme: ColorScheme.light(
            primary: navyBlue,
            secondary: skyBlue,
            background: offWhite,
            surface: Colors.white,
            onPrimary: skyBlue,
            onSecondary: navyBlue,
            onBackground: navyBlue,
            onSurface: navyBlue,
        ),
        cardTheme: CardTheme(
            color: Colors.white.withOpacity(0.85),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
            ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: skyBlue,
                foregroundColor: navyBlue,
                textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                ),
            ),
        ),
        textTheme: TextTheme(
            headlineSmall: TextStyle(
                color: navyBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
            ),
            bodyMedium: TextStyle(
                color: slate,
                fontFamily: 'Montserrat',
            ),
        ),
        fontFamily: 'Montserrat',
    );

    /// Configuration du thème sombre de l'application
    static ThemeData darkTheme = ThemeData(
        brightness: Brightness.dark,
        primaryColor: skyBlue,
        scaffoldBackgroundColor: slate,
        appBarTheme: AppBarTheme(
            backgroundColor: slate,
            elevation: 0,
            titleTextStyle: TextStyle(
                color: skyBlue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Montserrat',
            ),
            iconTheme: IconThemeData(color: skyBlue),
        ),
        colorScheme: ColorScheme.dark(
            primary: skyBlue,
            secondary: navyBlue,
            background: slate,
            surface: navyBlue,
            onPrimary: slate,
            onSecondary: skyBlue,
            onBackground: skyBlue,
            onSurface: skyBlue,
        ),
        cardTheme: CardTheme(
            color: navyBlue.withOpacity(0.7),
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
            ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: skyBlue,
                foregroundColor: slate,
                textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                ),
            ),
        ),
        textTheme: TextTheme(
            headlineSmall: TextStyle(
                color: skyBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
            ),
            bodyMedium: TextStyle(
                color: offWhite,
                fontFamily: 'Montserrat',
            ),
        ),
        fontFamily: 'Montserrat',
    );
} 