import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notificación única del proceso de sincronización de metadatos. Se
/// muestra una sola vez por proceso completo (no una por canción) y se
/// actualiza in place al terminar, en vez de mandar una notificación
/// nueva — usando siempre el mismo `_notificationId`.
class NotificationService {
  static const _channelId = 'metadata_sync';
  static const _channelName = 'Sincronización de biblioteca';
  static const _notificationId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> showSyncStarted() async {
    await _ensureInitialized();
    await Permission.notification.request();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
    );
    await _plugin.show(
      id: _notificationId,
      title: 'Actualizando tu biblioteca',
      body: 'Se están descargando los metadatos de tu biblioteca.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showSyncFinished(int updatedCount) async {
    await _ensureInitialized();
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: true,
    );
    await _plugin.show(
      id: _notificationId,
      title: 'Biblioteca actualizada',
      body: updatedCount > 0
          ? 'Se completaron los metadatos de $updatedCount canciones.'
          : 'No se encontraron metadatos nuevos.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());
