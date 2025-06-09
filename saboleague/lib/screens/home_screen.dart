import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;
  const HomeScreen({Key? key, this.onToggleTheme, this.isDarkMode = false}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    SearchScreen(),
    FavoritesScreen(),
    MapScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Recherche',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: 'Favoris',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Carte',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SABO League'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Mode clair' : 'Mode sombre',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
