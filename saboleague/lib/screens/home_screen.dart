import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';

/// Écran principal de l'application avec une barre de navigation inférieure
class HomeScreen extends StatefulWidget {
  // Callback pour basculer entre les thèmes clair/sombre
  final VoidCallback? onToggleTheme;
  // État actuel du thème (clair/sombre)
  final bool isDarkMode;
  
  // Constructeur avec des paramètres optionnels pour la gestion du thème
  const HomeScreen({Key? key, this.onToggleTheme, this.isDarkMode = false}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index de l'onglet actuellement sélectionné
  int _selectedIndex = 0;

  // Liste des écrans correspondant aux onglets de navigation
  final List<Widget> _screens = [
    SearchScreen(),      // Premier onglet : Recherche
    FavoritesScreen(),   // Deuxième onglet : Favoris
    MapScreen(),         // Troisième onglet : Carte
  ];


  // Configuration des éléments de la barre de navigation inférieure
  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.search),    // Icône pour l'onglet Recherche
      label: 'Recherche',          // Libellé de l'onglet
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite),  // Icône pour l'onglet Favoris
      label: 'Favoris',            // Libellé de l'onglet
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map),       // Icône pour l'onglet Carte
      label: 'Carte',              // Libellé de l'onglet
    ),
  ];

  // Gestion du changement d'onglet
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Met à jour l'index de l'onglet sélectionné
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec titre et bouton de changement de thème
      appBar: AppBar(
        title: Text('SABO League'),  // Titre de l'application
        actions: [
          // Bouton pour basculer entre les thèmes clair/sombre
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Mode clair' : 'Mode sombre',
            onPressed: widget.onToggleTheme,  // Appel du callback de changement de thème
          ),
        ],
      ),
      // Corps de l'application qui affiche l'écran correspondant à l'onglet sélectionné
      body: _screens[_selectedIndex],
      // Barre de navigation inférieure
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,  // Configuration des éléments de la barre
        currentIndex: _selectedIndex,  // Onglet actuellement sélectionné
        selectedItemColor: Theme.of(context).colorScheme.primary,  // Couleur de l'onglet actif
        onTap: _onItemTapped,  // Gestionnaire d'événements pour le changement d'onglet
      ),
    );
  }
}
