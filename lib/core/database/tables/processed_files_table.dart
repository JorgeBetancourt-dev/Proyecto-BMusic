import 'package:drift/drift.dart';

/// Registro de canciones ya consultadas contra los servicios remotos
/// (MusicBrainz / Cover Art Archive / TheAudioDB) para completar
/// metadatos. Evita volver a preguntar por la misma canción en cada
/// escaneo, según la regla del documento del proyecto.
@DataClassName('ProcessedFileEntity')
class ProcessedFiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get filePath => text().unique()();

  DateTimeColumn get processedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// true si el servicio remoto sí encontró y completó los metadatos.
  BoolColumn get metadataFound =>
      boolean().withDefault(const Constant(false))();
}
