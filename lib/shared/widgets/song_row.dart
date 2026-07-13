import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/song.dart';
import '../theme/app_theme.dart';

/// Fila de canción reutilizable en toda la app: biblioteca, selección
/// rápida y cola de reproducción.
class SongRow extends StatelessWidget {
  const SongRow({
    super.key,
    required this.song,
    this.index,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.coverSize = 38,
  });

  final Song song;
  final int? index;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double coverSize;

  // ... dentro de build(), cambia:
  // return InkWell(
  //   onTap: onTap,
  // por:
  // return InkWell(
  //   onTap: onTap,
  //   onLongPress: onLongPress,

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: isPlaying
                  ? const Text(
                      '♪',
                      style: TextStyle(color: AppColors.amber, fontSize: 12),
                    )
                  : Text(
                      index != null ? index!.toString().padLeft(2, '0') : '',
                      style: AppTheme.mono(fontSize: 11),
                    ),
            ),
            const SizedBox(width: 12),
            _SongCover(song: song, size: coverSize),
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
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 13.5,
                      color: isPlaying ? AppColors.amber : AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    song.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(song.duration),
              style: AppTheme.mono(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SongCover extends StatelessWidget {
  const _SongCover({required this.song, required this.size});

  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    final artworkPath = song.artworkPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: artworkPath != null
          ? Image.file(
              File(artworkPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Si el archivo de portada no existe o está corrupto, cae
              // al gradiente placeholder en vez de romper la UI.
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.coverGradientFor(song.title),
      ),
    );
  }
}
