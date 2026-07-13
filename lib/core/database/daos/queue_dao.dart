import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/queue_table.dart';
import '../tables/songs_table.dart';

part 'queue_dao.g.dart';

@DriftAccessor(tables: [Queue, Songs])
class QueueDao extends DatabaseAccessor<AppDatabase> with _$QueueDaoMixin {
  QueueDao(super.db);

  /// Cola actual, en orden. Se usa tanto para la pantalla del reproductor
  /// como para restaurarla al reabrir la app.
  Stream<List<SongEntity>> watchQueue() {
    final query = select(queue).join([
      innerJoin(songs, songs.id.equalsExp(queue.songId)),
    ])..orderBy([OrderingTerm.asc(queue.position)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(songs)).toList(),
    );
  }

  /// Reemplaza toda la cola por la lista de canciones dada, en ese orden.
  Future<void> setQueue(List<int> songIds) async {
    await transaction(() async {
      await delete(queue).go();
      for (var i = 0; i < songIds.length; i++) {
        await into(
          queue,
        ).insert(QueueCompanion.insert(songId: songIds[i], position: i));
      }
    });
  }

  Future<void> clearQueue() => delete(queue).go();
}
