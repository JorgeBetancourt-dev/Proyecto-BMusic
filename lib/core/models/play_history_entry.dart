import 'package:flutter/foundation.dart';

import '../database/database.dart';

@immutable
class PlayHistoryEntry {
  const PlayHistoryEntry({
    required this.id,
    required this.songId,
    required this.playedAt,
  });

  final int id;
  final int songId;
  final DateTime playedAt;

  factory PlayHistoryEntry.fromEntity(PlayHistoryEntity entity) {
    return PlayHistoryEntry(
      id: entity.id,
      songId: entity.songId,
      playedAt: entity.playedAt,
    );
  }
}