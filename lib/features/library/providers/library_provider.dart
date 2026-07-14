import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../core/providers/database_provider.dart';

/// Todas las canciones de la biblioteca, en tiempo real (se actualiza
/// sola cuando el escaneo agregue canciones nuevas).
final allSongsProvider = StreamProvider<List<Song>>((ref) {
  final dao = ref.watch(songsDaoProvider);
  return dao.watchAllSongs().map((rows) => rows.map(Song.fromEntity).toList());
});

/// true mientras hay un escaneo de carpeta en curso. Lo usa el botón de
/// "Seleccionar carpeta" para mostrar un spinner y evitar doble-tap.
final isScanningLibraryProvider = StateProvider<bool>((ref) => false);

/// Texto de búsqueda actual en la biblioteca.
final librarySearchQueryProvider = StateProvider<String>((ref) => '');

/// Carpeta de música elegida por el usuario.
/// Carpeta de música elegida por el usuario. Persistida en drift para
/// no pedirla de nuevo en cada apertura de la app.
final selectedFolderPathProvider = StreamProvider<String?>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return dao.watchSettings().map((settings) => settings?.musicFolderPath);
});

/// Canciones filtradas según el texto de búsqueda (título, artista o
/// álbum).
final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(allSongsProvider);
  final query = ref.watch(librarySearchQueryProvider).trim().toLowerCase();

  return songsAsync.whenData((songs) {
    if (query.isEmpty) return songs;
    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          (song.artist?.toLowerCase().contains(query) ?? false) ||
          (song.album?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});
