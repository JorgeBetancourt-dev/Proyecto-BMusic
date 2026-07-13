import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/daos/songs_dao.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'local_metadata_service.dart';

/// Resumen de un escaneo, útil para mostrar feedback en la UI
/// (ej. "18 canciones nuevas").
class ScanResult {
  const ScanResult({
    required this.added,
    required this.skippedExisting,
    required this.failed,
    required this.totalFiles,
  });

  final int added;
  final int skippedExisting;
  final int failed;
  final int totalFiles;
}

/// Escanea una carpeta del dispositivo, extrae metadatos locales de cada
/// canción y las guarda en la base de datos. No completa metadatos vía
/// MusicBrainz: eso lo hace `remote_metadata_service.dart`, tomando como
/// punto de partida `songsDao.getSongsWithIncompleteMetadata()`.
class LibraryScannerService {
  LibraryScannerService(this._songsDao, this._localMetadataService);

  final SongsDao _songsDao;
  final LocalMetadataService _localMetadataService;

  Future<ScanResult> scanFolder(String folderPath) async {
    final folder = Directory(folderPath);
    if (!folder.existsSync()) {
      throw ArgumentError('La carpeta no existe: $folderPath');
    }

    final audioFiles = folder
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) => supportedFileExtensions.any(
            (ext) => file.path.toLowerCase().endsWith(ext),
          ),
        )
        .toList();

    var added = 0;
    var skippedExisting = 0;
    var failed = 0;

    for (final file in audioFiles) {
      try {
        // Si el archivo ya está en la biblioteca, no lo releemos. Evita
        // trabajo innecesario en bibliotecas grandes en cada escaneo.
        final existing = await _songsDao.getSongByPath(file.path);
        if (existing != null) {
          skippedExisting++;
          continue;
        }

        final metadata = await _localMetadataService.read(file);
        final artworkPath = metadata.artwork != null
            ? await _saveArtwork(file.path, metadata.artwork!)
            : null;

        final companion = SongsCompanion.insert(
          filePath: file.path,
          title: metadata.title ?? _titleFromFileName(file.path),
          artist: Value(metadata.artist),
          album: Value(metadata.album),
          genre: Value(metadata.genre),
          year: Value(metadata.year),
          trackNumber: Value(metadata.trackNumber),
          durationMs: Value(metadata.durationMs),
          artworkPath: Value(artworkPath),
          lyrics: Value(metadata.lyrics),
          metadataComplete: Value(metadata.isComplete),
        );

        await _songsDao.upsertSong(companion);
        added++;
      } catch (_) {
        // Un archivo corrupto o con un formato no soportado no debe
        // frenar el resto del escaneo.
        failed++;
      }
    }

    return ScanResult(
      added: added,
      skippedExisting: skippedExisting,
      failed: failed,
      totalFiles: audioFiles.length,
    );
  }

  Future<String> _saveArtwork(String songPath, List<int> bytes) async {
    final dir = await getApplicationSupportDirectory();
    final artworkDir = Directory(p.join(dir.path, 'artwork'));
    if (!artworkDir.existsSync()) {
      artworkDir.createSync(recursive: true);
    }
    final file = File(p.join(artworkDir.path, '${songPath.hashCode}.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _titleFromFileName(String path) => p.basenameWithoutExtension(path);
}

/// Se apoya en `songsDaoProvider` (definido junto al resto de providers de
/// base de datos) para no duplicar la instancia del DAO.
final libraryScannerServiceProvider = Provider<LibraryScannerService>((ref) {
  return LibraryScannerService(
    ref.watch(songsDaoProvider),
    LocalMetadataService(),
  );
});
