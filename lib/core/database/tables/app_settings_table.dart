import 'package:drift/drift.dart';

/// Configuración de la app en una sola fila (siempre `id = 0`). Guarda lo
/// necesario para restaurar el estado al reabrir la app: la carpeta de
/// música seleccionada y qué canción de la cola estaba sonando.
@DataClassName('AppSettingsEntity')
class AppSettingsTable extends Table {
  IntColumn get id => integer()();

  TextColumn get musicFolderPath => text().nullable()();

  /// Posición (0-based) dentro de la cola persistida que estaba sonando
  /// al cerrar la app. Null si no había nada reproduciéndose.
  IntColumn get currentQueueIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
