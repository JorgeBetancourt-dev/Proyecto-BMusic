import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static const _rowId = 0;

  Future<AppSettingsEntity?> getSettings() {
    return (select(
      appSettingsTable,
    )..where((s) => s.id.equals(_rowId))).getSingleOrNull();
  }

  Stream<AppSettingsEntity?> watchSettings() {
    return (select(
      appSettingsTable,
    )..where((s) => s.id.equals(_rowId))).watchSingleOrNull();
  }

  Future<void> setMusicFolderPath(String path) {
    return into(appSettingsTable).insertOnConflictUpdate(
      AppSettingsTableCompanion.insert(
        id: Value(_rowId),
        musicFolderPath: Value(path),
      ),
    );
  }

  Future<void> setCurrentQueueIndex(int? index) {
    return into(appSettingsTable).insertOnConflictUpdate(
      AppSettingsTableCompanion.insert(
        id: Value(_rowId),
        currentQueueIndex: Value(index),
      ),
    );
  }
}
