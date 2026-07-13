import 'package:drift/drift.dart';

import 'playlists_table.dart';
import 'songs_table.dart';

/// Tabla puente N:M: qué canciones pertenecen a qué playlist y en qué
/// orden.
@DataClassName('PlaylistSongEntity')
class PlaylistSongs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();

  IntColumn get songId =>
      integer().references(Songs, #id, onDelete: KeyAction.cascade)();

  /// Posición dentro de la playlist, para poder reordenar canciones.
  IntColumn get position => integer()();

  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}