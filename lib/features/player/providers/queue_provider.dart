import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/song.dart';
import '../../../core/services/audio_player_service.dart';

/// Cola de reproducción en memoria: la lista de canciones y cuál está
/// sonando ahora. Persistirla en la tabla `queue` de drift queda para
/// cuando se necesite recuperarla entre sesiones.
class QueueState {
  const QueueState({this.songs = const [], this.currentIndex = -1});

  final List<Song> songs;
  final int currentIndex;

  Song? get currentSong => currentIndex >= 0 && currentIndex < songs.length
      ? songs[currentIndex]
      : null;

  bool get hasNext => currentIndex >= 0 && currentIndex < songs.length - 1;
  bool get hasPrevious => currentIndex > 0;

  QueueState copyWith({List<Song>? songs, int? currentIndex}) {
    return QueueState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier(this._audioPlayer) : super(const QueueState()) {
    // Cuando una canción termina, avanza sola a la siguiente de la cola.
    _completionSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      if (playerState.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

  final AudioPlayerService _audioPlayer;
  late final StreamSubscription<PlayerState> _completionSubscription;

  Future<void> playFrom(List<Song> songs, int startIndex) async {
    state = QueueState(songs: songs, currentIndex: startIndex);
    await _audioPlayer.playSong(songs[startIndex]);
  }

  Future<void> next() async {
    if (!state.hasNext) return;
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(currentIndex: nextIndex);
    await _audioPlayer.playSong(state.songs[nextIndex]);
  }

  Future<void> previous() async {
    if (!state.hasPrevious) return;
    final prevIndex = state.currentIndex - 1;
    state = state.copyWith(currentIndex: prevIndex);
    await _audioPlayer.playSong(state.songs[prevIndex]);
  }

  Future<void> playIndexInQueue(int index) async {
    if (index < 0 || index >= state.songs.length) return;
    state = state.copyWith(currentIndex: index);
    await _audioPlayer.playSong(state.songs[index]);
  }

  @override
  void dispose() {
    _completionSubscription.cancel();
    super.dispose();
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier(ref.watch(audioPlayerServiceProvider));
});
