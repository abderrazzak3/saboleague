import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

/// Point d'entrée principal de l'application SABO League
/// Initialise et lance l'application
void main() {
  runApp(MyApp());
}

/// Widget racine de l'application
/// Gère le thème global et la navigation principale
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

/// État du widget racine
/// Contient la logique de gestion du thème (clair/sombre)
class _MyAppState extends State<MyApp> {
  /// Mode de thème actuel de l'application
  ThemeMode _themeMode = ThemeMode.light;

  /// Bascule entre le thème clair et sombre
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// Titre de l'application affiché dans la barre de titre
      title: 'SABO League',
      /// Configuration du thème clair
      theme: AppTheme.lightTheme,
      /// Configuration du thème sombre
      darkTheme: AppTheme.darkTheme,
      /// Mode de thème actuel
      themeMode: _themeMode,
      /// Écran d'accueil de l'application
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
      /// Désactive la bannière de débogage
      debugShowCheckedModeBanner: false,
    );
  }
}