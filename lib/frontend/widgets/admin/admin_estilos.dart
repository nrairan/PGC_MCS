import 'package:flutter/material.dart';
import 'package:mcs/frontend/formularios/formulario_horario.dart'
    show kVerdeOscuro;

/// Colores y estilos compartidos por los componentes administrativos.
///
/// Reutiliza el verde institucional ya definido en el formulario de horarios y
/// toma superficies, bordes y textos del tema activo (claro u oscuro).
class AdminEstilos {
  AdminEstilos._();

  /// Verde principal de la app (mismo que la pantalla de horarios).
  static const Color verde = kVerdeOscuro;

  /// Rojo usado para acciones destructivas y errores (mismo que horarios).
  static const Color peligro = Color(0xFFC62828);

  /// Color de texto secundario según el tema.
  static Color textoSecundario(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;

  /// Estilo del botón principal verde.
  static ButtonStyle botonPrincipal() => ElevatedButton.styleFrom(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}
