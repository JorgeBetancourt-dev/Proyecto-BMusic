import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/audio_player_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../providers/player_state_provider.dart';

/// Mini-reproductor fijo, visible arriba del bottom nav en todas las
/// pantallas excepto en el Reproductor. Si no hay ninguna canción
/// cargada todavía, no se muestra nada.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);

    if (song == null) return const SizedBox.shrink();

    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.goNamed('reproductor'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            _MiniCover(artworkPath: song.artworkPath, title: song.title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(fontSize: 12.5),
                  ),
                  Text(
                    song.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
            _PlayPauseButton(isPlaying: isPlaying),
          ],
        ),
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.artworkPath, required this.title});

  final String? artworkPath;
  final String title;

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: artworkPath != null
          ? Image.file(
              File(artworkPath!),
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(gradient: AppTheme.coverGradientFor(title)),
    );
  }
}

class _PlayPauseButton extends ConsumerWidget {
  const _PlayPauseButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () async {
        final service = ref.read(audioPlayerServiceProvider);
        if (isPlaying) {
          await service.pause();
        } else {
          await service.resume();
        }
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.amber,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: 14,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
