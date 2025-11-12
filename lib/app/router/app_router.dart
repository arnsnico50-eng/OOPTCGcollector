import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

import '../constants/app_constants.dart';
import '../../features/collection/screens/collection_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.searchRoute,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: AppConstants.searchRoute,
            name: AppConstants.searchRouteName,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppConstants.collectionRoute,
            name: AppConstants.collectionRouteName,
            builder: (context, state) => const CollectionScreen(),
          ),
          GoRoute(
            path: AppConstants.scannerRoute,
            name: AppConstants.scannerRouteName,
            builder: (context, state) => const ScannerScreen(),
          ),
          GoRoute(
            path: AppConstants.settingsRoute,
            name: AppConstants.settingsRouteName,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    const NavigationDestination(
      icon: Icon(Icons.collection),
      label: 'Collection',
    ),
    const NavigationDestination(
      icon: Icon(Icons.camera_alt),
      label: 'Scanner',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  final List<String> _routes = [
    AppConstants.searchRoute,
    AppConstants.collectionRoute,
    AppConstants.scannerRoute,
    AppConstants.settingsRoute,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          context.go(_routes[index]);
        },
        destinations: _destinations,
      ),
    );
  }
}