import 'package:drift/drift.dart';

/// `@DataClassName` evita que la fila generada por drift se llame igual
/// que el modelo de dominio `Song` (core/models/song.dart). La fila cruda
/// se llama `SongEntity`; el modelo de dominio es el que usa la UI.
@DataClassName('SongEntity')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Ruta absoluta al archivo de audio. Es la clave para saber si una
  /// canción ya existe en la biblioteca durante el escaneo.
  TextColumn get filePath => text().unique()();

  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();

  /// Duración de la canción en milisegundos.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// Ruta a la portada ya extraída del archivo (o descargada), no el
  /// archivo de audio en sí.
  TextColumn get artworkPath => text().nullable()();

  TextColumn get lyrics => text().nullable()();

  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  /// true cuando título, artista, álbum, género y portada están completos.
  /// Se usa para decidir qué canciones necesitan buscarse en MusicBrainz.
  BoolColumn get metadataComplete =>
      boolean().withDefault(const Constant(false))();
}