import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

/// Metadatos ya normalizados y listos para mapear a `SongsCompanion`.
/// Aísla al resto de la app de los tipos internos de
/// `audio_metadata_reader` (Mp3Metadata, VorbisMetadata, etc.).
class LocalMetadata {
  const LocalMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.year,
    required this.trackNumber,
    required this.durationMs,
    required this.artwork,
    required this.lyrics,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int durationMs;
  final Uint8List? artwork;
  final String? lyrics;

  /// Mismo criterio que `Songs.metadataComplete`: título, artista, álbum,
  /// género y portada presentes. Si falta algo, la canción queda marcada
  /// como candidata para `remote_metadata_service` más adelante.
  bool get isComplete =>
      _hasValue(title) &&
      _hasValue(artist) &&
      _hasValue(album) &&
      _hasValue(genre) &&
      artwork != null;

  static bool _hasValue(String? value) => value != null && value.isNotEmpty;
}

/// Lee metadatos embebidos (ID3, Vorbis Comments, iTunes ilst) de un
/// archivo de audio local. No hace ninguna llamada de red: eso queda para
/// `remote_metadata_service.dart` (MusicBrainz / Cover Art Archive).
class LocalMetadataService {
  Future<LocalMetadata> read(File file) async {
    final metadata = readMetadata(file, getImage: true);

    return LocalMetadata(
      title: _nonEmpty(metadata.title),
      artist: _nonEmpty(metadata.artist),
      album: _nonEmpty(metadata.album),
      genre: metadata.genres.isNotEmpty ? metadata.genres.join(', ') : null,
      year: metadata.year?.year,
      trackNumber: metadata.trackNumber,
      durationMs: metadata.duration?.inMilliseconds ?? 0,
      artwork: metadata.pictures.isNotEmpty
          ? Uint8List.fromList(metadata.pictures.first.bytes)
          : null,
      lyrics: _nonEmpty(metadata.lyrics),
    );
  }

  String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
