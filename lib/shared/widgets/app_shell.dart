import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/player/ui/widgets/mini_player.dart';
import 'bottom_nav.dart';

/// Envuelve las 4 pestañas (Música, Biblioteca, Playlists, Reproductor).
/// Muestra el mini-player fijo en todas las pantallas salvo en Reproductor,
/// igual que en el mockup.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _playerTabIndex = 3;

  @override
  Widget build(BuildContext context) {
    final isPlayerTab = navigationShell.currentIndex == _playerTabIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPlayerTab) const MiniPlayer(),
          AppBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}
