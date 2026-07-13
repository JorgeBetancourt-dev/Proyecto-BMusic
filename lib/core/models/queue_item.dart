import 'package:flutter/foundation.dart';

import 'song.dart';

/// Una canción dentro de la cola de reproducción, con su posición.
@immutable
class QueueItem {
  const QueueItem({required this.position, required this.song});

  final int position;
  final Song song;
}