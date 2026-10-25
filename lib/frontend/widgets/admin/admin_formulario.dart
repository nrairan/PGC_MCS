import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/admin/admin_estados.dart';
import 'package:mcs/frontend/widgets/admin/admin_estilos.dart';

/// Abre un formulario administrativo como ventana modal.
///
/// Devuelve `true` si el formulario se guardó (el formulario debe cerrarse con
/// `Navigator.pop(context, true)` tras guardar) y `null` si se cerró sin
/// guardar. No se cierra al tocar fuera, para no perder datos por accidente.
Future<bool?> mostrarAdminFormulario(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: builder,
  );
}

/// Decoración común de los campos: bordes redondeados, etiqueta legible y
/// asterisco en los obligatorios (mismo estilo del formulario de horarios).
InputDecoration adminDecoracion(
  String etiqueta, {
  bool obligatorio = false,
  String? hint,
  String? ayuda,
  IconData? icono,
}) {
  return InputDecoration(
    labelText: obligatorio ? '$etiqueta *' : etiqueta,
    hintText: hint,
    helperText: ayuda,
    prefixIcon: icono == null ? null : Icon(icono),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AdminEstilos.verde, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Marco de un formulario administrativo (creación o edición).
///
/// Es solo la estructura visual: el estado (controladores, `guardando`,
/// `errorGeneral`) lo maneja el formulario de cada entidad, que construye sus
/// campos con [AdminCampoTexto] y [AdminSelector] y los pasa en `campos`.
class AdminFormulario extends StatelessWidget {
  /// Título completo, p. ej. "Editar salón" o "Nuevo programa".
  final String titulo;
  final String? descripcion;
  final IconData icono;
  final bool esEdicion;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;

  /// Acción de guardar. Debe validar el formulario antes de llamar a la API.
  final VoidCallback? onGuardar;
  final bool guardando;

  /// Mensaje de error devuelto por la API o de conexión, mostrado arriba.
  final String? errorGeneral;
  final String? textoGuardar;
  final double anchoMaximo;

  const AdminFormulario({
    super.key,
    required this.titulo,
    required this.icono,
    required this.esEdicion,
    required this.formKey,
    required this.campos,
    required this.onGuardar,
    this.descripcion,
    this.guardando = false,
    this.errorGeneral,
    this.textoGuardar,
    this.anchoMaximo = 560,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AdminEstilos.verde.withValues(alpha: 0.1),
                    child: Icon(icono, color: AdminEstilos.verde),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (descripcion != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            descripcion!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AdminEstilos.textoSecundario(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorGeneral != null) ...[
                        AdminBannerError(mensaje: errorGeneral!),
                        const SizedBox(height: 14),
                      ],
                      for (var i = 0; i < campos.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        campos[i],
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '* Campo obligatorio',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AdminEstilos.textoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed:
                        guardando ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: guardando ? null : onGuardar,
                    style: AdminEstilos.botonPrincipal(),
                    icon: guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      textoGuardar ??
                          (esEdicion ? 'Guardar cambios' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de texto administrativo con validación de obligatorio incluida.
class AdminCampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String etiqueta;
  final bool obligatorio;
  final String? hint;
  final String? ayuda;
  final IconData? icono;
  final TextInputType? teclado;
  final bool oculto;
  final bool habilitado;
  final int maxLineas;

  /// Validación adicional; se ejecuta solo si el campo no está vacío.
  final String? Function(String valor)? validador;

  const AdminCampoTexto({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.obligatorio = false,
    this.hint,
    this.ayuda,
    this.icono,
    this.teclado,
    this.oculto = false,
    this.habilitado = true,
    this.maxLineas = 1,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      obscureText: oculto,
      enabled: habilitado,
      maxLines: oculto ? 1 : maxLineas,
      decoration: adminDecoracion(
        etiqueta,
        obligatorio: obligatorio,
        hint: hint,
        ayuda: ayuda,
        icono: icono,
      ),
      validator: (valor) {
        final texto = (valor ?? '').trim();
        if (texto.isEmpty) {
          return obligatorio ? 'Este campo es obligatorio' : null;
        }
        return validador?.call(texto);
      },
    );
  }
}

/// Opción de un [AdminSelector].
class AdminOpcion<T> {
  final T valor;
  final String etiqueta;

  const AdminOpcion(this.valor, this.etiqueta);
}

/// Selector desplegable para relaciones (programa, coordinador, rol, etc.).
///
/// Si `valor` no está entre las `opciones` se muestra sin selección, para
/// evitar errores cuando la lista aún no se ha cargado.
class AdminSelector<T> extends StatelessWidget {
  final T? valor;
  final String etiqueta;
  final List<AdminOpcion<T>> opciones;
  final ValueChanged<T?>? onChanged;
  final bool obligatorio;
  final String? hint;
  final String? ayuda;
  final IconData? icono;

  const AdminSelector({
    super.key,
    required this.valor,
    required this.etiqueta,
    required this.opciones,
    required this.onChanged,
    this.obligatorio = false,
    this.hint,
    this.ayuda,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final seleccion =
        opciones.any((o) => o.valor == valor) ? valor : null;

    return DropdownButtonFormField<T>(
      key: ValueKey('$etiqueta-$seleccion-${opciones.length}'),
      initialValue: seleccion,
      isExpanded: true,
      decoration: adminDecoracion(
        etiqueta,
        obligatorio: obligatorio,
        hint: hint,
        ayuda: ayuda,
        icono: icono,
      ),
      items: [
        for (final o in opciones)
          DropdownMenuItem<T>(
            value: o.valor,
            child: Text(o.etiqueta, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => obligatorio && v == null ? 'Selecciona una opción' : null,
    );
  }
}

/// Selector de varias opciones con casillas (relaciones muchos a muchos,
/// p. ej. los gestores de un núcleo temático).
class AdminMultiSelector<T> extends StatelessWidget {
  final String etiqueta;
  final List<AdminOpcion<T>> opciones;
  final Set<T> seleccion;
  final ValueChanged<Set<T>>? onChanged;

  /// Texto mostrado cuando no hay opciones disponibles.
  final String mensajeVacio;

  const AdminMultiSelector({
    super.key,
    required this.etiqueta,
    required this.opciones,
    required this.seleccion,
    required this.onChanged,
    this.mensajeVacio = 'No hay opciones disponibles.',
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: adminDecoracion(
        etiqueta,
        ayuda: '${seleccion.length} seleccionado(s)',
      ),
      child: opciones.isEmpty
          ? Text(
              mensajeVacio,
              style: TextStyle(
                fontSize: 13,
                color: AdminEstilos.textoSecundario(context),
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in opciones)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AdminEstilos.verde,
                      title: Text(o.etiqueta, overflow: TextOverflow.ellipsis),
                      value: seleccion.contains(o.valor),
                      onChanged: onChanged == null
                          ? null
                          : (marcado) {
                              final nueva = Set<T>.of(seleccion);
                              if (marcado == true) {
                                nueva.add(o.valor);
                              } else {
                                nueva.remove(o.valor);
                              }
                              onChanged!(nueva);
                            },
                    ),
                ],
              ),
            ),
    );
  }
}

/// Interruptor (sí/no) con el mismo borde redondeado de los demás campos.
class AdminInterruptor extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool valor;
  final ValueChanged<bool>? onChanged;

  const AdminInterruptor({
    super.key,
    required this.titulo,
    required this.valor,
    required this.onChanged,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SwitchListTile(
        title: Text(titulo),
        subtitle: subtitulo == null ? null : Text(subtitulo!),
        value: valor,
        onChanged: onChanged,
      ),
    );
  }
}
