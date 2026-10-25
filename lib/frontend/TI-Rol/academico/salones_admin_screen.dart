import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/TI-Rol/academico/salon_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Gestión de salones del rol TI.
class SalonesAdminScreen extends StatelessWidget {
  const SalonesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const service = AcademicoAdminService();
    return AdminCrudPagina<SalonAdmin>(
      tituloBarra: 'MCS - Gestión de salones',
      titulo: 'Gestión de salones',
      descripcion:
          'Consulta, crea, edita y elimina los salones, su capacidad y su tipo.',
      icono: Icons.meeting_room_outlined,
      etiquetaCrear: 'Nuevo salón',
      hintBusqueda: 'Buscar por código o edificio',
      plural: 'salones',
      tituloVacio: 'Aún no hay salones registrados',
      tituloEliminar: 'Eliminar salón',
      mensajeCreado: 'Salón creado',
      mensajeActualizado: 'Salón actualizado',
      mensajeEliminado: 'Salón eliminado',
      mensajeYaNoExiste: 'El salón ya no existe.',
      cargar: service.salones,
      coincide: (s, q) => s.coincide(q),
      nombreEliminar: (s) => s.codigo,
      eliminar: (s) =>
          service.api.eliminar(AcademicoAdminService.recursoSalones, s.id),
      formulario: (s) => SalonFormDialog(salon: s),
      tarjeta: (s, onEditar, onEliminar) => AdminTarjeta(
        titulo: s.codigo,
        icono: Icons.meeting_room_outlined,
        datos: [
          if (s.edificio.isNotEmpty)
            AdminDato('Edificio: ${s.edificio}', icono: Icons.apartment),
          if (s.capacidad != null)
            AdminDato('Capacidad: ${s.capacidad}',
                icono: Icons.event_seat_outlined),
        ],
        etiquetas: [if (s.tipoEtiqueta.isNotEmpty) s.tipoEtiqueta],
        tooltipEditar: 'Editar salón',
        tooltipEliminar: 'Eliminar salón',
        onEditar: onEditar,
        onEliminar: onEliminar,
      ),
    );
  }
}
