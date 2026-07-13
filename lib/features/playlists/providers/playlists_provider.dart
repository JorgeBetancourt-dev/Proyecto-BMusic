import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/providers/database_provider.dart';

/// Una playlist junto con lo que se muestra en la fila de la lista
/// (cantidad de canciones y duración total).
class PlaylistSummary {
  const PlaylistSummary({
    required this.playlist,
    required this.songCount,
    required this.totalDuration,
  });

  final Playlist playlist;
  final int songCount;
  final Duration totalDuration;
}

final playlistsProvider = StreamProvider<List<PlaylistSummary>>((ref) {
  final dao = ref.watch(playlistsDaoProvider);
  return dao.watchPlaylistsWithStats().map(
    (rows) => rows
        .map(
          (row) => PlaylistSummary(
            playlist: Playlist.fromEntity(row.playlist),
            songCount: row.songCount,
            totalDuration: Duration(milliseconds: row.totalDurationMs),
          ),
        )
        .toList(),
  );
});
