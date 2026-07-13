import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/song_row.dart';
import '../providers/player_state_provider.dart';
import '../providers/queue_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vinylController;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;

    // El disco gira solo mientras hay reproducción activa.
    if (isPlaying && !_vinylController.isAnimating) {
      _vinylController.repeat();
    } else if (!isPlaying && _vinylController.isAnimating) {
      _vinylController.stop();
    }

    if (currentSong == null) {
      return const SafeArea(child: _NothingPlaying());
    }

    final queueState = ref.watch(queueProvider);
    final upcoming = queueState.songs.sublist(
      (queueState.currentIndex + 1).clamp(0, queueState.songs.length),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          children: [
            Text(
              // TODO: reflejar el origen real (playlist, recomendadas,
              // etc.) cuando exista esa información en la cola.
              'REPRODUCIENDO DESDE · BIBLIOTECA',
              style: AppTheme.mono(
                fontSize: 10.5,
              ).copyWith(letterSpacing: 2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 26),
            _Vinyl(controller: _vinylController, isPlaying: isPlaying),
            const SizedBox(height: 20),
            Text(
              currentSong.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 23),
            ),
            const SizedBox(height: 4),
            Text(
              currentSong.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 26),
            _ProgressBar(totalDuration: currentSong.duration),
            const SizedBox(height: 24),
            const _Controls(),
            const SizedBox(height: 30),
            _QueueSection(
              upcoming: upcoming,
              startIndex: queueState.currentIndex + 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _Vinyl extends StatelessWidget {
  const _Vinyl({required this.controller, required this.isPlaying});

  final AnimationController controller;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: controller.value * 2 * math.pi,
                child: child,
              );
            },
            child: CustomPaint(
              size: const Size(230, 230),
              painter: const _VinylPainter(),
            ),
          ),
          Positioned(
            top: -6,
            right: 8,
            child: AnimatedRotation(
              turns: isPlaying ? -4 / 360 : -18 / 360,
              duration: const Duration(milliseconds: 400),
              alignment: Alignment.topRight,
              child: const _Tonearm(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tonearm extends StatelessWidget {
  const _Tonearm();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          Positioned(
            top: 6,
            right: 6,
            child: Transform.rotate(
              angle: 28 * math.pi / 180,
              alignment: Alignment.topCenter,
              child: Container(
                width: 4,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.mauve,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.mauve,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el disco de vinilo a mano: surcos concéntricos + etiqueta
/// central ámbar. CSS usa `repeating-radial-gradient`, que no tiene
/// equivalente directo en Flutter, así que lo replicamos con un
/// CustomPainter en vez de aproximarlo con un gradiente.
class _VinylPainter extends CustomPainter {
  const _VinylPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF17101B));

    const grooveColors = [Color(0xFF241A29), Color(0xFF17101B)];
    var groove = 0;
    for (var r = radius; r > radius * 0.18; r -= 3) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = grooveColors[groove % grooveColors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      groove++;
    }

    canvas.drawCircle(center, radius * 0.16, Paint()..color = AppColors.amber);
    canvas.drawCircle(
      center,
      radius * 0.03,
      Paint()..color = const Color(0xFF100A14),
    );
  }

  @override
  bool shouldRepaint(covariant _VinylPainter oldDelegate) => false;
}

class _ProgressBar extends ConsumerWidget {
  const _ProgressBar({required this.totalDuration});

  final Duration totalDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(playbackPositionProvider).valueOrNull ?? Duration.zero;
    final totalMs = totalDuration.inMilliseconds;
    final fraction = totalMs > 0
        ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: AppColors.surface2,
            valueColor: const AlwaysStoppedAnimation(AppColors.amber),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(position), style: AppTheme.mono()),
            Text(_formatDuration(totalDuration), style: AppTheme.mono()),
          ],
        ),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueProvider);
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mezclar y repetir: el mockup los muestra pero pendiente
        // implementar el modo en queue_provider.dart.
        const Opacity(
          opacity: 0.6,
          child: Icon(Icons.shuffle, size: 20, color: AppColors.cream),
        ),
        const SizedBox(width: 22),
        _CtrlIconButton(
          icon: Icons.skip_previous,
          enabled: queueState.hasPrevious,
          onPressed: () => ref.read(queueProvider.notifier).previous(),
        ),
        const SizedBox(width: 22),
        _PlayPauseBigButton(isPlaying: isPlaying),
        const SizedBox(width: 22),
        _CtrlIconButton(
          icon: Icons.skip_next,
          enabled: queueState.hasNext,
          onPressed: () => ref.read(queueProvider.notifier).next(),
        ),
        const SizedBox(width: 22),
        const Opacity(
          opacity: 0.6,
          child: Icon(Icons.repeat, size: 20, color: AppColors.cream),
        ),
      ],
    );
  }
}

class _CtrlIconButton extends StatelessWidget {
  const _CtrlIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.cream),
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }
}

class _PlayPauseBigButton extends ConsumerWidget {
  const _PlayPauseBigButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () async {
        final service = ref.read(audioPlayerServiceProvider);
        if (isPlaying) {
          await service.pause();
        } else {
          await service.resume();
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: AppColors.amber,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.ink,
          size: 26,
        ),
      ),
    );
  }
}

class _QueueSection extends StatelessWidget {
  const _QueueSection({required this.upcoming, required this.startIndex});

  final List<Song> upcoming;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'A continuación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'COLA',
              style: AppTheme.mono(
                fontSize: 10.5,
                color: AppColors.terracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No hay más canciones en la cola',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...upcoming.asMap().entries.map((entry) {
            final position = entry.key;
            final song = entry.value;
            return Consumer(
              builder: (context, ref, _) {
                return SongRow(
                  index: position + 1,
                  song: song,
                  coverSize: 32,
                  onTap: () => ref
                      .read(queueProvider.notifier)
                      .playIndexInQueue(startIndex + position),
                );
              },
            );
          }),
      ],
    );
  }
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.album_outlined, size: 34, color: AppColors.mauve),
            const SizedBox(height: 12),
            Text(
              'Nada sonando todavía. Elige una canción desde tu biblioteca.',
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
