/// Coque applicative — barre de navigation basse (5 onglets).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import 'announcements_screen.dart';
import 'contributions_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _onglet = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final moi = session.moi!;
    final screens = [
      HomeScreen(key: ValueKey('accueil-${moi.role}')),
      const ContributionsScreen(),
      const ProjectsScreen(),
      const AnnouncementsScreen(),
      ProfileScreen(moi: moi),
    ];

    return Scaffold(
      body: IndexedStack(index: _onglet, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Cotisations',
          ),
          const NavigationDestination(
            icon: Icon(Icons.engineering_outlined),
            selectedIcon: Icon(Icons.engineering_rounded),
            label: 'Projets',
          ),
          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Annonces',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
