import 'package:drift/drift.dart';

import 'songs_table.dart';

/// Una fila por cada reproducción. Sirve tanto para "Escuchadas
/// recientemente" (últimos 7 días) como para el algoritmo de
/// recomendaciones (artistas/géneros más frecuentes).
@DataClassName('PlayHistoryEntity')
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get songId =>
      integer().references(Songs, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}