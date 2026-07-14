import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/song_row.dart';
import '../providers/library_provider.dart';
import '../../../core/services/library_scanner_service.dart';

import '../../player/providers/queue_provider.dart';
import '../../player/providers/player_state_provider.dart';

import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';
import '../../../shared/widgets/add_to_playlist_sheet.dart';
import 'dart:async' show unawaited;

import '../../../core/services/remote_metadata_service.dart';
import '../../../core/providers/database_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(filteredSongsProvider);
    final totalCount = ref.watch(allSongsProvider).valueOrNull?.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biblioteca',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            _FolderChip(songCount: totalCount),
            const SizedBox(height: 18),
            const _SearchBar(),
            const SizedBox(height: 6),
            Expanded(
              child: songsAsync.when(
                data: (songs) => songs.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final currentSong = ref.watch(currentSongProvider);
                          return SongRow(
                            index: index + 1,
                            song: song,
                            isPlaying: currentSong?.filePath == song.filePath,
                            onTap: () => ref
                                .read(queueProvider.notifier)
                                .playFrom(songs, index),
                            onLongPress: () =>
                                showAddToPlaylistSheet(context, ref, song),
                          );
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'No se pudo cargar la biblioteca',
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
}

class _FolderChip extends ConsumerWidget {
  const _FolderChip({required this.songCount});

  final int? songCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderPath = ref.watch(selectedFolderPathProvider).valueOrNull;
    final isScanning = ref.watch(isScanningLibraryProvider);

    final label = folderPath == null
        ? 'Ninguna carpeta seleccionada'
        : songCount == null
        ? folderPath
        : '$folderPath · $songCount canciones';

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.mono(fontSize: 10.5),
          ),
        ),
        const SizedBox(width: 8),
        _PickFolderButton(
          hasFolder: folderPath != null,
          isScanning: isScanning,
          onPressed: isScanning ? null : () => _pickFolder(context, ref),
        ),
      ],
    );
  }

  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return; // el usuario cerró el diálogo sin elegir

    final hasPermission = await _requestAudioPermission();
    if (!hasPermission) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitas darle permiso a la app para leer música desde '
            'Ajustes → Apps → proyecto_musica → Permisos.',
          ),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    await ref.read(settingsDaoProvider).setMusicFolderPath(path);
    ref.read(isScanningLibraryProvider.notifier).state = true;

    try {
      final result = await ref
          .read(libraryScannerServiceProvider)
          .scanFolder(path);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.added} canciones nuevas · '
            '${result.skippedExisting} ya en tu biblioteca'
            '${result.failed > 0 ? ' · ${result.failed} con errores' : ''}',
          ),
          backgroundColor: AppColors.surface,
        ),
      );

      // Completa metadatos faltantes en segundo plano — no bloquea el
      // SnackBar ni el resto de la UI mientras corre.
      unawaited(ref.read(remoteMetadataServiceProvider).syncIfPossible());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo escanear la carpeta: $e'),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      ref.read(isScanningLibraryProvider.notifier).state = false;
    }
  }

  Future<bool> _requestAudioPermission() async {
    if (!Platform.isAndroid) return true;
    // Pedimos ambos: en Android 13+ el que importa es `audio`, en
    // versiones anteriores es `storage`. El que no aplica en cada
    // versión simplemente se resuelve como concedido sin pedir nada.
    final statuses = await [Permission.audio, Permission.storage].request();
    return statuses.values.any((status) => status.isGranted);
  }
}

class _PickFolderButton extends StatelessWidget {
  const _PickFolderButton({
    required this.hasFolder,
    required this.isScanning,
    required this.onPressed,
  });

  final bool hasFolder;
  final bool isScanning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isScanning)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.amber,
                ),
              )
            else
              const Icon(
                Icons.folder_open_outlined,
                size: 13,
                color: AppColors.amber,
              ),
            const SizedBox(width: 4),
            Text(
              isScanning
                  ? 'Escaneando…'
                  : hasFolder
                  ? 'Cambiar'
                  : 'Seleccionar carpeta',
              style: const TextStyle(
                fontSize: 10.5,
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

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.mauve),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (value) =>
                  ref.read(librarySearchQueryProvider.notifier).state = value,
              style: const TextStyle(color: AppColors.cream, fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Buscar en tu biblioteca',
                hintStyle: TextStyle(color: AppColors.mauve, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              Icons.library_music_outlined,
              size: 34,
              color: AppColors.mauve,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay canciones en tu biblioteca',
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
