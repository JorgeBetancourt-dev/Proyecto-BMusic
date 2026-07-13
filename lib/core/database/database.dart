import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/history_dao.dart';
import 'daos/playlists_dao.dart';
import 'daos/queue_dao.dart';
import 'daos/songs_dao.dart';
import 'tables/play_history_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/processed_files_table.dart';
import 'tables/queue_table.dart';
import 'tables/songs_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Songs, Playlists, PlaylistSongs, PlayHistory, Queue, ProcessedFiles],
  daos: [SongsDao, PlaylistsDao, HistoryDao, QueueDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    // drift_flutter elige automáticamente la mejor implementación nativa
    // según la plataforma (SQLite en Windows/Android/iOS/macOS/Linux).
    return driftDatabase(name: 'proyecto_musica_db');
  }
}
