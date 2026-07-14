import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';

/// Envuelve el `AudioPlayer` de just_audio en una única instancia
/// compartida por toda la app.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;

  /// Carga y reproduce [song]. El `MediaItem` es lo que
  /// just_audio_background muestra en la notificación y el lockscreen
  /// (título, artista, portada).
  /// Carga [song] sin reproducirla. Se usa para restaurar la cola al
  /// abrir la app, dejando la canción lista pero pausada.
  Future<void> loadSong(Song song) async {
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.file(song.filePath),
        tag: MediaItem(
          id: song.filePath,
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
        ),
      ),
    );
  }

  Future<void> playSong(Song song) async {
    await loadSong(song);
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});
