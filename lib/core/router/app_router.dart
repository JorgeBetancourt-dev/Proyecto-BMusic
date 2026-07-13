import 'package:go_router/go_router.dart';

import '../../features/library/ui/library_screen.dart';
import '../../features/music_home/ui/music_home_screen.dart';
import '../../features/player/ui/player_screen.dart';
import '../../features/playlists/ui/playlists_screen.dart';
import '../../shared/widgets/app_shell.dart';

/// GoRouter con StatefulShellRoute: mantiene el estado de cada pestaña
/// al cambiar entre ellas (igual que el comportamiento del mockup, donde
/// cada pantalla conserva su scroll/estado al volver a ella).
final appRouter = GoRouter(
  initialLocation: '/musica',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/musica',
              name: 'musica',
              builder: (context, state) => const MusicHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/biblioteca',
              name: 'biblioteca',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/playlists',
              name: 'playlists',
              builder: (context, state) => const PlaylistsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reproductor',
              name: 'reproductor',
              builder: (context, state) => const PlayerScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);