import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/playlist_songs_table.dart';
import '../tables/playlists_table.dart';
import '../tables/songs_table.dart';

part 'playlists_dao.g.dart';

/// Playlist junto con estadísticas ya calculadas en la consulta (cantidad
/// de canciones y duración total), para no tener que sumarlas en Dart
/// cada vez que la UI se reconstruye.
class PlaylistWithStats {
  const PlaylistWithStats({
    required this.playlist,
    required this.songCount,
    required this.totalDurationMs,
  });

  final PlaylistEntity playlist;
  final int songCount;
  final int totalDurationMs;
}

@DriftAccessor(tables: [Playlists, PlaylistSongs, Songs])
class PlaylistsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  /// Playlists con su cantidad de canciones y duración total, para la
  /// pantalla de lista (evita consultar cada playlist por separado).
  Stream<List<PlaylistWithStats>> watchPlaylistsWithStats() {
    final songCount = playlistSongs.id.count();
    final totalDuration = songs.durationMs.sum();

    final query =
        select(playlists).join([
            leftOuterJoin(
              playlistSongs,
              playlistSongs.playlistId.equalsExp(playlists.id),
            ),
            leftOuterJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
          ])
          ..addColumns([songCount, totalDuration])
          ..groupBy([playlists.id])
          ..orderBy([OrderingTerm.desc(playlists.updatedAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PlaylistWithStats(
          playlist: row.readTable(playlists),
          songCount: row.read(songCount) ?? 0,
          totalDurationMs: row.read(totalDuration) ?? 0,
        );
      }).toList();
    });
  }

  Stream<List<PlaylistEntity>> watchAllPlaylists() => (select(
    playlists,
  )..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();

  Future<int> createPlaylist(String name) {
    final now = DateTime.now();
    return into(playlists).insert(
      PlaylistsCompanion.insert(
        name: name,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> renamePlaylist(int id, String newName) {
    return (update(playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deletePlaylist(int id) =>
      (delete(playlists)..where((p) => p.id.equals(id))).go();

  /// IDs de las playlists que ya contienen esta canción — para pintar
  /// los checkboxes correctos al abrir el selector "Agregar a playlist".
  Future<Set<int>> getPlaylistIdsContainingSong(int songId) async {
    final rows = await (select(
      playlistSongs,
    )..where((ps) => ps.songId.equals(songId))).get();
    return rows.map((row) => row.playlistId).toSet();
  }

  /// Agrega una canción al final de la playlist.
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final maxPositionRow =
        await (selectOnly(playlistSongs)
              ..addColumns([playlistSongs.position.max()])
              ..where(playlistSongs.playlistId.equals(playlistId)))
            .getSingleOrNull();

    final nextPosition =
        (maxPositionRow?.read(playlistSongs.position.max()) ?? -1) + 1;

    await into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: songId,
        position: nextPosition,
      ),
    );
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) {
    return (delete(playlistSongs)..where(
          (ps) => ps.playlistId.equals(playlistId) & ps.songId.equals(songId),
        ))
        .go();
  }

  /// Canciones de una playlist, en orden.
  Stream<List<SongEntity>> watchSongsInPlaylist(int playlistId) {
    final query =
        select(
            playlistSongs,
          ).join([innerJoin(songs, songs.id.equalsExp(playlistSongs.songId))])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistSongs.position)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(songs)).toList(),
    );
  }
}
