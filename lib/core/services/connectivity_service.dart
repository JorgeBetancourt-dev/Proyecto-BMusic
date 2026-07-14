import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Responde una sola pregunta: ¿hay Wi-Fi disponible ahora mismo? La
/// sincronización remota de metadatos solo debe correr por Wi-Fi, nunca
/// por datos móviles (como pediste en tu documento de especificación).
class ConnectivityService {
  final _connectivity = Connectivity();

  Future<bool> hasWifi() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }
}

final connectivityServiceProvider = Provider((ref) => ConnectivityService());