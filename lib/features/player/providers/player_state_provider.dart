import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_player_service.dart';
import 'queue_provider.dart';

/// Canción que suena ahora (o null si no hay nada cargado). La fuente de
/// verdad de "qué está sonando" es la cola; esto solo la expone más
/// cómoda para la UI.
final currentSongProvider = Provider((ref) {
  return ref.watch(queueProvider).currentSong;
});

/// true mientras el reproductor está en play (no pausado).
final isPlayingProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(audioPlayerServiceProvider)
      .playerStateStream
      .map((state) => state.playing);
});

/// Progreso de la canción actual, para animar la barra de progreso.
final playbackPositionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioPlayerServiceProvider).positionStream;
});
