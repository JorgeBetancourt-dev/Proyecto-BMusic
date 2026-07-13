import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/song.dart';
import '../../core/providers/database_provider.dart';
import '../../features/playlists/providers/playlists_provider.dart';
import '../theme/app_theme.dart';

/// Abre el selector de playlists para agregar/quitar [song]. Reutilizable
/// desde cualquier pantalla que muestre un `SongRow` (Biblioteca, cola,
/// detalle de playlist).
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  final containingIds = await ref
      .read(playlistsDaoProvider)
      .getPlaylistIdsContainingSong(song.id);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _AddToPlaylistSheet(song: song, initiallyContainingIds: containingIds),
  );
}

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  const _AddToPlaylistSheet({
    required this.song,
    required this.initiallyContainingIds,
  });

  final Song song;
  final Set<int> initiallyContainingIds;

  @override
  ConsumerState<_AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  late Set<int> _containingIds;

  @override
  void initState() {
    super.initState();
    _containingIds = {...widget.initiallyContainingIds};
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar a playlist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              widget.song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: playlistsAsync.when(
                data: (playlists) => playlists.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Todavía no tienes playlists. Crea una desde la '
                          'pestaña Playlists.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index].playlist;
                          final isIn = _containingIds.contains(playlist.id);
                          return CheckboxListTile(
                            value: isIn,
                            activeColor: AppColors.amber,
                            checkColor: AppColors.ink,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              playlist.name,
                              style: const TextStyle(color: AppColors.cream),
                            ),
                            onChanged: (checked) =>
                                _toggle(playlist.id, checked ?? false),
                          );
                        },
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No se pudieron cargar tus playlists',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(int playlistId, bool addIt) async {
    setState(() {
      if (addIt) {
        _containingIds.add(playlistId);
      } else {
        _containingIds.remove(playlistId);
      }
    });

    final dao = ref.read(playlistsDaoProvider);
    if (addIt) {
      await dao.addSongToPlaylist(playlistId, widget.song.id);
    } else {
      await dao.removeSongFromPlaylist(playlistId, widget.song.id);
    }
  }
}
