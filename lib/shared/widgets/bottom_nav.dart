import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra inferior con los 4 tabs: Música, Biblioteca, Playlists, Reproductor.
/// Recibe el índice actual y un callback de navegación desde el AppShell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(icon: Icons.graphic_eq_rounded, label: 'Música'),
    _NavItemData(icon: Icons.menu_rounded, label: 'Biblioteca'),
    _NavItemData(icon: Icons.grid_view_rounded, label: 'Playlists'),
    _NavItemData(icon: Icons.album_outlined, label: 'Reproductor'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final active = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 19,
                        color: active ? AppColors.amber : AppColors.mauve,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.03,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.amber : AppColors.mauve,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
