import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/database/daos/queue_dao.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/models/song.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/audio_player_service.dart';

class QueueState {
  const QueueState({this.songs = const [], this.currentIndex = -1});

  final List<Song> songs;
  final int currentIndex;

  Song? get currentSong =>
      currentIndex >= 0 && currentIndex < songs.length
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
  QueueNotifier(this._audioPlayer, this._queueDao, this._settingsDao)
    : super(const QueueState()) {
    _completionSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      if (playerState.processingState == ProcessingState.completed) {
        next();
      }
    });
    _restore();
  }

  final AudioPlayerService _audioPlayer;
  final QueueDao _queueDao;
  final SettingsDao _settingsDao;
  late final StreamSubscription<PlayerState> _completionSubscription;

  /// Restaura la cola guardada la última vez que se cerró la app. Carga
  /// la canción actual sin reproducirla automáticamente — el usuario
  /// decide si le da play.
  Future<void> _restore() async {
    final songs = await _queueDao
        .watchQueue()
        .first
        .then((rows) => rows.map(Song.fromEntity).toList());
    if (songs.isEmpty) return;

    final settings = await _settingsDao.getSettings();
    final restoredIndex = (settings?.currentQueueIndex ?? 0).clamp(
      0,
      songs.length - 1,
    );

    state = QueueState(songs: songs, currentIndex: restoredIndex);
    await _audioPlayer.loadSong(songs[restoredIndex]);
  }

  Future<void> playFrom(List<Song> songs, int startIndex) async {
    state = QueueState(songs: songs, currentIndex: startIndex);
    await _audioPlayer.playSong(songs[startIndex]);
    await _persistQueue();
  }

  Future<void> next() async {
    if (!state.hasNext) return;
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(currentIndex: nextIndex);
    await _audioPlayer.playSong(state.songs[nextIndex]);
    await _persistCurrentIndex();
  }

  Future<void> previous() async {
    if (!state.hasPrevious) return;
    final prevIndex = state.currentIndex - 1;
    state = state.copyWith(currentIndex: prevIndex);
    await _audioPlayer.playSong(state.songs[prevIndex]);
    await _persistCurrentIndex();
  }

  Future<void> playIndexInQueue(int index) async {
    if (index < 0 || index >= state.songs.length) return;
    state = state.copyWith(currentIndex: index);
    await _audioPlayer.playSong(state.songs[index]);
    await _persistCurrentIndex();
  }

  Future<void> _persistQueue() async {
    await _queueDao.setQueue(state.songs.map((s) => s.id).toList());
    await _persistCurrentIndex();
  }

  Future<void> _persistCurrentIndex() {
    return _settingsDao.setCurrentQueueIndex(state.currentIndex);
  }

  @override
  void dispose() {
    _completionSubscription.cancel();
    super.dispose();
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier(
    ref.watch(audioPlayerServiceProvider),
    ref.watch(queueDaoProvider),
    ref.watch(settingsDaoProvider),
  );
});