import 'package:flutter/material.dart';
import 'package:mcs/frontend/pantallas_historial/historial_ti_screen.dart';

/// Pantalla de Registros / Logs para el rol de TI.
/// Redirige a `HistorialTiScreen` con el menú lateral de TI (`LateralTi`).
class RegistrosScreen extends StatelessWidget {
  const RegistrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistorialTiScreen();
  }
}
