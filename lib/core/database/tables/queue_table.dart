import 'package:drift/drift.dart';

import 'songs_table.dart';

/// Cola de reproducción actual ("A continuación" en la pantalla del
/// reproductor). Se persiste para poder restaurarla al reabrir la app.
@DataClassName('QueueEntity')
class Queue extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get songId =>
      integer().references(Songs, #id, onDelete: KeyAction.cascade)();

  /// Orden dentro de la cola.
  IntColumn get position => integer()();

  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}