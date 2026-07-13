import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/playlists_provider.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playlists',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 2),
            playlistsAsync.maybeWhen(
              data: (playlists) => Text(
                '${playlists.length} colecciones',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            _NewPlaylistButton(onTap: () => _createPlaylist(context, ref)),
            const SizedBox(height: 18),
            Expanded(
              child: playlistsAsync.when(
                data: (playlists) => playlists.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: playlists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final summary = playlists[index];
                          return _PlaylistRow(
                            summary: summary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(
                                  playlistId: summary.playlist.id,
                                  playlistName: summary.playlist.name,
                                ),
                              ),
                            ),
                            onRename: () =>
                                _renamePlaylist(context, ref, summary),
                            onDelete: () =>
                                _deletePlaylist(context, ref, summary),
                          );
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'No se pudieron cargar las playlists',
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

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await _promptForName(context, title: 'Nueva playlist');
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistsDaoProvider).createPlaylist(name.trim());
  }

  Future<void> _renamePlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistSummary summary,
  ) async {
    final name = await _promptForName(
      context,
      title: 'Renombrar playlist',
      initialValue: summary.playlist.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(playlistsDaoProvider)
        .renamePlaylist(summary.playlist.id, name.trim());
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Eliminar playlist?'),
        content: Text(
          'Se eliminará "${summary.playlist.name}". Las canciones no se '
          'borran de tu biblioteca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(playlistsDaoProvider).deletePlaylist(summary.playlist.id);
    }
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.cream),
          decoration: const InputDecoration(hintText: 'Nombre de la playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _NewPlaylistButton extends StatelessWidget {
  const _NewPlaylistButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.amber),
            SizedBox(width: 8),
            Text(
              'Nueva playlist',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.summary,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final PlaylistSummary summary;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final playlist = summary.playlist;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.coverGradientFor(playlist.name),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${summary.songCount} canciones · '
                    '${_formatDuration(summary.totalDuration)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: AppColors.mauve,
              ),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music_outlined,
              size: 34,
              color: AppColors.mauve,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes playlists. Crea la primera arriba.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mauve),
            ),
          ],
        ),
      ),
    );
  }
}
