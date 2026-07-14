import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// Instancia única de la base de datos para toda la app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
final settingsDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).settingsDao,
);
final songsDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).songsDao,
);
final playlistsDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).playlistsDao,
);
final historyDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).historyDao,
);
final queueDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).queueDao,
);
