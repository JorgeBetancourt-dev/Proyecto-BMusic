import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/daos/songs_dao.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';

/// Completa metadatos faltantes (artista, álbum, portada) de las
/// canciones que quedaron marcadas como incompletas durante el escaneo,
/// usando MusicBrainz (metadatos) y Cover Art Archive (portadas). Solo
/// corre por Wi-Fi y solo sobre archivos que no se hayan consultado
/// antes (tabla `processed_files`), como pediste en tu documento.
class RemoteMetadataService {
  RemoteMetadataService(
    this._songsDao,
    this._connectivity,
    this._notifications,
  );

  final SongsDao _songsDao;
  final ConnectivityService _connectivity;
  final NotificationService _notifications;

  // MusicBrainz exige un User-Agent identificable — reemplaza el email
  // por uno tuyo real antes de publicar la app.
  static const _userAgent = 'ProyectoMusica/0.1.0 (tu-email@ejemplo.com)';

  /// MusicBrainz pide máximo 1 solicitud por segundo para uso anónimo
  /// sin API key.
  static const _requestDelay = Duration(milliseconds: 1100);

  /// Punto de entrada: revisa si hay algo pendiente y, si las
  /// condiciones lo permiten (Wi-Fi disponible), lo sincroniza. Seguro
  /// de llamar después de cada escaneo — si no hay nada pendiente, no
  /// hace nada y no muestra ninguna notificación.
  Future<void> syncIfPossible() async {
    final incomplete = await _songsDao.getSongsWithIncompleteMetadata();
    final pending = <SongEntity>[];
    for (final song in incomplete) {
      if (!await _songsDao.isFileProcessed(song.filePath)) {
        pending.add(song);
      }
    }

    if (pending.isEmpty) return;
    if (!await _connectivity.hasWifi()) return;

    await _notifications.showSyncStarted();

    var updated = 0;
    for (final song in pending) {
      try {
        final found = await _completeMetadata(song);
        if (found) updated++;
      } catch (_) {
        // Un fallo de red o de parseo en una canción no debe frenar el
        // resto del proceso.
      } finally {
        await _songsDao.markFileProcessed(song.filePath, found: true);
        await Future.delayed(_requestDelay);
      }
    }

    await _notifications.showSyncFinished(updated);
  }

  Future<bool> _completeMetadata(SongEntity song) async {
    final match = await _searchRecording(
      title: song.title,
      artist: song.artist,
    );
    if (match == null) return false;

    String? artworkPath;
    if (match.releaseId != null) {
      artworkPath = await _downloadCoverArt(match.releaseId!, song.filePath);
    }

    final finalArtist = song.artist ?? match.artist;
    final finalAlbum = song.album ?? match.album;
    final finalArtwork = artworkPath ?? song.artworkPath;

    await _songsDao.upsertSong(
      SongsCompanion(
        filePath: Value(song.filePath),
        title: Value(song.title),
        artist: Value(finalArtist),
        album: Value(finalAlbum),
        artworkPath: Value(finalArtwork),
        metadataComplete: Value(
          _hasValue(finalArtist) &&
              _hasValue(finalAlbum) &&
              _hasValue(song.genre) &&
              finalArtwork != null,
        ),
      ),
    );
    return true;
  }

  bool _hasValue(String? value) => value != null && value.isNotEmpty;

  Future<_RecordingMatch?> _searchRecording({
    required String title,
    String? artist,
  }) async {
    final escapedTitle = _escapeQuery(title);
    final query = artist != null && artist.isNotEmpty
        ? 'recording:"$escapedTitle" AND artist:"${_escapeQuery(artist)}"'
        : 'recording:"$escapedTitle"';

    final uri = Uri.https('musicbrainz.org', '/ws/2/recording/', {
      'query': query,
      'fmt': 'json',
      'limit': '1',
    });

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final recordings = data['recordings'] as List<dynamic>?;
    if (recordings == null || recordings.isEmpty) return null;

    final recording = recordings.first as Map<String, dynamic>;
    final artistCredit = recording['artist-credit'] as List<dynamic>?;
    final artistName = artistCredit != null && artistCredit.isNotEmpty
        ? (artistCredit.first as Map<String, dynamic>)['name'] as String?
        : null;

    final releases = recording['releases'] as List<dynamic>?;
    final release = releases != null && releases.isNotEmpty
        ? releases.first as Map<String, dynamic>
        : null;

    return _RecordingMatch(
      artist: artistName,
      album: release?['title'] as String?,
      releaseId: release?['id'] as String?,
    );
  }

  String _escapeQuery(String value) => value.replaceAll('"', '\\"');

  Future<String?> _downloadCoverArt(String releaseId, String songPath) async {
    final uri = Uri.https(
      'coverartarchive.org',
      '/release/$releaseId/front-250',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final dir = await getApplicationSupportDirectory();
    final artworkDir = Directory(p.join(dir.path, 'artwork'));
    if (!artworkDir.existsSync()) {
      artworkDir.createSync(recursive: true);
    }
    final file = File(p.join(artworkDir.path, '${songPath.hashCode}.jpg'));
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}

class _RecordingMatch {
  const _RecordingMatch({
    required this.artist,
    required this.album,
    required this.releaseId,
  });

  final String? artist;
  final String? album;
  final String? releaseId;
}

final remoteMetadataServiceProvider = Provider<RemoteMetadataService>((ref) {
  return RemoteMetadataService(
    ref.watch(songsDaoProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});
