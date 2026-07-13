import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../library/providers/library_provider.dart';

/// Selección rápida: un orden aleatorio de tu biblioteca. Sin historial
/// real todavía — cuando exista el historial de reproducción, esto se
/// puede reemplazar por recomendaciones de verdad sin tocar la UI.
final quickPickProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(allSongsProvider);

  return songsAsync.whenData((songs) {
    final shuffled = [...songs]..shuffle();
    return shuffled;
  });
});
