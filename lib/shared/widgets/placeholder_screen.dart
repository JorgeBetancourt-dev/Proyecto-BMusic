import 'package:flutter/material.dart';

/// Pantalla temporal usada mientras se construye el contenido real de
/// cada sección. Se irá reemplazando fase por fase.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title\n(pantalla pendiente)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
