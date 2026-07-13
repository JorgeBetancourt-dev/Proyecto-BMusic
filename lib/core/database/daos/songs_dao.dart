import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/processed_files_table.dart';
import '../tables/songs_table.dart';

part 'songs_dao.g.dart';

@DriftAccessor(tables: [Songs, ProcessedFiles])
class SongsDao extends DatabaseAccessor<AppDatabase> with _$SongsDaoMixin {
  SongsDao(super.db);

  // ---------- Canciones ----------

  Future<List<SongEntity>> getAllSongs() => select(songs).get();

  Stream<List<SongEntity>> watchAllSongs() => select(songs).watch();

  Future<SongEntity?> getSongById(int id) {
    return (select(songs)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<SongEntity?> getSongByPath(String filePath) {
    return (select(
      songs,
    )..where((s) => s.filePath.equals(filePath))).getSingleOrNull();
  }

  /// Inserta o reemplaza (por `filePath`) una canción. Se usa durante el
  /// escaneo de la carpeta de música.
  Future<int> upsertSong(SongsCompanion song) {
    return into(songs).insertOnConflictUpdate(song);
  }

  Future<bool> updateSong(SongsCompanion song) => update(songs).replace(song);

  Future<int> deleteSong(int id) =>
      (delete(songs)..where((s) => s.id.equals(id))).go();

  Future<List<SongEntity>> searchSongs(String query) {
    final likeQuery = '%$query%';
    return (select(songs)..where(
          (s) =>
              s.title.like(likeQuery) |
              s.artist.like(likeQuery) |
              s.album.like(likeQuery),
        ))
        .get();
  }

  /// Canciones a las que les falta algún metadato: candidatas para
  /// consultar en MusicBrainz / Cover Art Archive / TheAudioDB.
  Future<List<SongEntity>> getSongsWithIncompleteMetadata() {
    return (select(
      songs,
    )..where((s) => s.metadataComplete.equals(false))).get();
  }

  // ---------- Archivos ya procesados (evita reconsultar) ----------

  Future<bool> isFileProcessed(String filePath) async {
    final row = await (select(
      processedFiles,
    )..where((p) => p.filePath.equals(filePath))).getSingleOrNull();
    return row != null;
  }

  Future<void> markFileProcessed(String filePath, {required bool found}) {
    return into(processedFiles).insertOnConflictUpdate(
      ProcessedFilesCompanion.insert(
        filePath: filePath,
        metadataFound: Value(found),
      ),
    );
  }
}
