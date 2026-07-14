import '../database/daos/history_dao.dart';
import '../database/daos/songs_dao.dart';
import '../models/song.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';

/// Algoritmo simple de recomendaciones: mira qué artistas y géneros son
/// los más frecuentes en el historial reciente, y busca canciones de la
/// biblioteca que los compartan pero que no se hayan escuchado hace
/// poco. Sin machine learning ni servicios externos — solo conteo.
class RecommendationService {
  RecommendationService(this._historyDao, this._songsDao);

  final HistoryDao _historyDao;
  final SongsDao _songsDao;

  static const _lookbackDays = 7;
  static const _maxRecommendations = 10;
  static const _minRecommendations = 5;
  static const _topArtistsAndGenres = 3;

  Future<List<Song>> getRecommendations() async {
    final since = DateTime.now().subtract(const Duration(days: _lookbackDays));
    final playedSongs = await _historyDao.getPlayedSongsSince(since);

    // Sin historial todavía: no hay base para recomendar nada.
    if (playedSongs.isEmpty) return [];

    final recentlyPlayedIds = playedSongs.map((s) => s.id).toSet();

    final artistCounts = <String, int>{};
    final genreCounts = <String, int>{};
    for (final song in playedSongs) {
      if (song.artist != null && song.artist!.isNotEmpty) {
        artistCounts[song.artist!] = (artistCounts[song.artist!] ?? 0) + 1;
      }
      if (song.genre != null && song.genre!.isNotEmpty) {
        genreCounts[song.genre!] = (genreCounts[song.genre!] ?? 0) + 1;
      }
    }

    final topArtists = _topKeys(artistCounts);
    final topGenres = _topKeys(genreCounts);

    final allSongs = await _songsDao.getAllSongs();

    final matching = allSongs.where((song) {
      if (recentlyPlayedIds.contains(song.id)) return false;
      final matchesArtist = topArtists.contains(song.artist);
      final matchesGenre = topGenres.contains(song.genre);
      return matchesArtist || matchesGenre;
    }).toList()..shuffle();

    if (matching.length >= _minRecommendations) {
      return matching.take(_maxRecommendations).map(Song.fromEntity).toList();
    }

    // No hay suficientes canciones que compartan artista/género: se
    // completa con canciones al azar no escuchadas recientemente, para
    // llegar al mínimo de 5 que pide el documento.
    final matchingIds = matching.map((s) => s.id).toSet();
    final fallback =
        allSongs
            .where(
              (song) =>
                  !recentlyPlayedIds.contains(song.id) &&
                  !matchingIds.contains(song.id),
            )
            .toList()
          ..shuffle();

    return [
      ...matching,
      ...fallback,
    ].take(_maxRecommendations).map(Song.fromEntity).toList();
  }

  List<String> _topKeys(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(_topArtistsAndGenres).map((e) => e.key).toList();
  }
}

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(
    ref.watch(historyDaoProvider),
    ref.watch(songsDaoProvider),
  );
});
