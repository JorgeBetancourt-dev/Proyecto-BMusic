import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/play_history_table.dart';
import '../tables/songs_table.dart';

part 'history_dao.g.dart';

@DriftAccessor(tables: [PlayHistory, Songs])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  Future<void> logPlay(int songId) {
    return into(
      playHistory,
    ).insert(PlayHistoryCompanion.insert(songId: songId));
  }

  /// Canciones escuchadas desde [since], sin duplicados, ordenadas de la
  /// más reciente a la más antigua. Usado por "Escuchadas recientemente".
  Future<List<SongEntity>> getRecentlyPlayed({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));

    final query =
        select(
            playHistory,
          ).join([innerJoin(songs, songs.id.equalsExp(playHistory.songId))])
          ..where(playHistory.playedAt.isBiggerOrEqualValue(since))
          ..orderBy([OrderingTerm.desc(playHistory.playedAt)]);

    final rows = await query.get();

    final seen = <int>{};
    final result = <SongEntity>[];
    for (final row in rows) {
      final song = row.readTable(songs);
      if (seen.add(song.id)) result.add(song);
    }
    return result;
  }

  /// Igual que `getRecentlyPlayed`, pero como stream: se recalcula solo
  /// cada vez que se registra una reproducción nueva. Lo usa "Selección
  /// rápida" para mezclarse en tiempo real con lo que vas escuchando.
  Stream<List<SongEntity>> watchRecentlyPlayed({int days = 7}) {
    final since = DateTime.now().subtract(Duration(days: days));

    final query =
        select(
            playHistory,
          ).join([innerJoin(songs, songs.id.equalsExp(playHistory.songId))])
          ..where(playHistory.playedAt.isBiggerOrEqualValue(since))
          ..orderBy([OrderingTerm.desc(playHistory.playedAt)]);

    return query.watch().map((rows) {
      final seen = <int>{};
      final result = <SongEntity>[];
      for (final row in rows) {
        final song = row.readTable(songs);
        if (seen.add(song.id)) result.add(song);
      }
      return result;
    });
  }

  /// Todas las reproducciones (con repetidos) desde [since], como pares
  /// de canción. Es la materia prima para que `recommendation_service`
  /// calcule artistas/géneros más frecuentes.
  Future<List<SongEntity>> getPlayedSongsSince(DateTime since) async {
    final query =
        select(
            playHistory,
          ).join([innerJoin(songs, songs.id.equalsExp(playHistory.songId))])
          ..where(playHistory.playedAt.isBiggerOrEqualValue(since))
          ..orderBy([OrderingTerm.desc(playHistory.playedAt)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
  }

  Future<int> deleteAllHistory() => delete(playHistory).go();
}
