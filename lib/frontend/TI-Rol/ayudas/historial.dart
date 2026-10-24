import 'package:flutter/material.dart';
import 'package:mcs/frontend/pantallas_historial/historial_coordinador_screen.dart';

/// Pantalla de Historial para Coordinador.
/// Redirige al widget paginado con infinite scroll `HistorialCoordinadorScreen`.
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistorialCoordinadorScreen();
  }
}
