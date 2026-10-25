import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/TI-Rol/academico/nucleo_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Gestión de núcleos temáticos (asignaturas) del rol TI.
class NucleosAdminScreen extends StatelessWidget {
  const NucleosAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const service = AcademicoAdminService();
    return AdminCrudPagina<NucleoAdmin>(
      tituloBarra: 'MCS - Gestión de núcleos temáticos',
      titulo: 'Gestión de núcleos temáticos',
      descripcion:
          'Consulta, crea, edita y elimina los núcleos temáticos, su programa y sus gestores.',
      icono: Icons.menu_book_outlined,
      etiquetaCrear: 'Nuevo núcleo',
      hintBusqueda: 'Buscar por nombre, código, programa o gestor',
      plural: 'núcleos temáticos',
      tituloVacio: 'Aún no hay núcleos temáticos registrados',
      tituloEliminar: 'Eliminar núcleo temático',
      mensajeCreado: 'Núcleo temático creado',
      mensajeActualizado: 'Núcleo temático actualizado',
      mensajeEliminado: 'Núcleo temático eliminado',
      mensajeYaNoExiste: 'El núcleo temático ya no existe.',
      cargar: service.nucleos,
      coincide: (n, q) => n.coincide(q),
      nombreEliminar: (n) => n.nombre,
      advertenciaEliminar: (n) =>
          'Se eliminará el núcleo ${n.codigo}. Esta acción no se puede deshacer.',
      eliminar: (n) =>
          service.api.eliminar(AcademicoAdminService.recursoNucleos, n.id),
      formulario: (n) => NucleoFormDialog(nucleo: n),
      tarjeta: (n, onEditar, onEliminar) => AdminTarjeta(
        titulo: n.nombre,
        subtitulo: n.codigo.isEmpty ? null : 'Código: ${n.codigo}',
        icono: Icons.menu_book_outlined,
        datos: [
          if (n.programaNombre != null)
            AdminDato('Programa: ${n.programaNombre}',
                icono: Icons.school_outlined),
          if (n.creditos != null)
            AdminDato('Créditos: ${n.creditos}', icono: Icons.numbers),
          if (n.horasSemana > 0)
            AdminDato('Horas por semana: ${n.horasSemana}',
                icono: Icons.schedule),
          if (n.gestoresNombres.isNotEmpty)
            AdminDato('Gestores: ${n.gestoresNombres.join(', ')}',
                icono: Icons.groups_outlined),
        ],
        etiquetas: [
          if (n.semestre.isNotEmpty) 'Semestre ${n.semestre}',
          if (n.requiereSalaComputo) 'Sala de cómputo',
        ],
        tooltipEditar: 'Editar núcleo',
        tooltipEliminar: 'Eliminar núcleo',
        onEditar: onEditar,
        onEliminar: onEliminar,
      ),
    );
  }
}
