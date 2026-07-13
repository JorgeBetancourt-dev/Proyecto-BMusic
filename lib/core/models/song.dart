import 'package:flutter/foundation.dart';

import '../database/database.dart';

/// Modelo de dominio de una canción. Separado de `SongEntity` (la fila
/// cruda de drift) para que la UI y los servicios no dependan del motor
/// de base de datos.
@immutable
class Song {
  const Song({
    required this.id,
    required this.filePath,
    required this.title,
    required this.duration,
    required this.dateAdded,
    required this.metadataComplete,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.trackNumber,
    this.artworkPath,
    this.lyrics,
  });

  final int id;
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final Duration duration;
  final String? artworkPath;
  final String? lyrics;
  final DateTime dateAdded;
  final bool metadataComplete;

  factory Song.fromEntity(SongEntity entity) {
    return Song(
      id: entity.id,
      filePath: entity.filePath,
      title: entity.title,
      artist: entity.artist,
      album: entity.album,
      genre: entity.genre,
      year: entity.year,
      trackNumber: entity.trackNumber,
      duration: Duration(milliseconds: entity.durationMs),
      artworkPath: entity.artworkPath,
      lyrics: entity.lyrics,
      dateAdded: entity.dateAdded,
      metadataComplete: entity.metadataComplete,
    );
  }

  /// Texto "Artista · Álbum" listo para mostrar, con fallbacks cuando
  /// falta algún dato (mientras se completan los metadatos).
  String get subtitle {
    final parts = [
      if (artist != null && artist!.isNotEmpty) artist,
      if (album != null && album!.isNotEmpty) album,
    ];
    return parts.isEmpty ? 'Artista desconocido' : parts.join(' · ');
  }
}