import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../shared/theme/app_theme.dart';
import '../../player/providers/queue_provider.dart';
import '../providers/quick_pick_provider.dart';

class MusicHomeScreen extends ConsumerStatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  ConsumerState<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends ConsumerState<MusicHomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickPickAsync = ref.watch(quickPickProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppHeader(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selección rápida',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                quickPickAsync.maybeWhen(
                  data: (songs) => Text(
                    '${songs.length} canciones'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: quickPickAsync.when(
                data: (songs) => songs.isEmpty
                    ? const _EmptyState()
                    : _QuickPickPager(
                        songs: songs,
                        pageController: _pageController,
                        currentPage: _currentPage,
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        onSongTap: (index) => ref
                            .read(queueProvider.notifier)
                            .playFrom(songs, index),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'No se pudo cargar tu música',
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

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('BMusic', style: Theme.of(context).textTheme.titleLarge),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.amber, AppColors.terracotta],
              ),
            ),
            child: const Icon(
              Icons.music_note,
              size: 16,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPickPager extends StatelessWidget {
  const _QuickPickPager({
    required this.songs,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSongTap,
  });

  final List<Song> songs;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSongTap;

  static const _pageSize = 5;

  @override
  Widget build(BuildContext context) {
    final pageCount = (songs.length / _pageSize).ceil();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * _pageSize;
              final end = (start + _pageSize).clamp(0, songs.length);

              return Column(
                children: [
                  for (var i = start; i < end; i++)
                    _QuickPickRow(
                      song: songs[i],
                      onTap: () => onSongTap(i),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _PageDots(count: pageCount, current: currentPage),
      ],
    );
  }
}

class _QuickPickRow extends StatelessWidget {
  const _QuickPickRow({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  static const _size = 46.0;

  @override
  Widget build(BuildContext context) {
    final artworkPath = song.artworkPath;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: artworkPath != null
                  ? Image.file(
                      File(artworkPath),
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        gradient: AppTheme.coverGradientFor(song.title),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.amber : AppColors.line,
          ),
        );
      }),
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
            const Icon(Icons.graphic_eq, size: 34, color: AppColors.mauve),
            const SizedBox(height: 12),
            Text(
              'Selecciona una carpeta en Biblioteca para empezar a '
              'escuchar tu música.',
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