import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/recommendation_service.dart';
import '../../library/providers/library_provider.dart';

/// Selección rápida: mezcla canciones que ya escuchas seguido (historial
/// reciente) con recomendaciones por género/artista de esas mismas
/// canciones. Se recalcula solo cada vez que reproduces algo, así que si
/// empiezas a escuchar otro género, la mezcla se va ajustando con el
/// tiempo — sin necesidad de configurar nada manualmente.
final quickPickProvider = StreamProvider<List<Song>>((ref) {
  final historyDao = ref.watch(historyDaoProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  final librarySongs = ref.watch(allSongsProvider).valueOrNull ?? [];

  return historyDao.watchRecentlyPlayed().asyncMap((recentRows) async {
    if (librarySongs.isEmpty) return <Song>[];

    final recentlyPlayed = recentRows.map(Song.fromEntity).toList();

    // Sin historial todavía: mezcla simple de toda la biblioteca, igual
    // que antes de tener historial real.
    if (recentlyPlayed.isEmpty) {
      final shuffled = [...librarySongs]..shuffle();
      return shuffled;
    }

    final recommended = await recommendationService.getRecommendations();

    final mixed = [...recentlyPlayed.take(8), ...recommended];

    final seen = <int>{};
    final deduped = mixed.where((song) => seen.add(song.id)).toList()
      ..shuffle();
    return deduped;
  });
});
