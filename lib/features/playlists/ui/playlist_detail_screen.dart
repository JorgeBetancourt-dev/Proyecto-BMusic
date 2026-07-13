import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../core/providers/database_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/song_row.dart';
import '../../player/providers/player_state_provider.dart';
import '../../player/providers/queue_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  final int playlistId;
  final String playlistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(playlistsDaoProvider);

    return StreamBuilder<List<Song>>(
      stream: dao
          .watchSongsInPlaylist(playlistId)
          .map((rows) => rows.map(Song.fromEntity).toList()),
      builder: (context, snapshot) {
        final songs = snapshot.data ?? const [];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.cream),
            title: Text(
              playlistName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.play_circle_fill, size: 28),
                color: AppColors.amber,
                disabledColor: AppColors.mauve,
                onPressed: songs.isEmpty
                    ? null
                    : () => ref.read(queueProvider.notifier).playFrom(songs, 0),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '${songs.length} canciones',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: songs.isEmpty
                        ? Center(
                            child: Text(
                              'Esta playlist todavía no tiene canciones.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              return Consumer(
                                builder: (context, ref, _) {
                                  final currentSong = ref.watch(
                                    currentSongProvider,
                                  );
                                  return Dismissible(
                                    key: ValueKey(song.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      color: AppColors.terracotta,
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.cream,
                                      ),
                                    ),
                                    onDismissed: (_) =>
                                        dao.removeSongFromPlaylist(
                                          playlistId,
                                          song.id,
                                        ),
                                    child: SongRow(
                                      index: index + 1,
                                      song: song,
                                      isPlaying:
                                          currentSong?.filePath ==
                                          song.filePath,
                                      onTap: () => ref
                                          .read(queueProvider.notifier)
                                          .playFrom(songs, index),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
