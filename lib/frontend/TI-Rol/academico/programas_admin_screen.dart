import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/TI-Rol/academico/programa_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Gestión de programas académicos del rol TI.
class ProgramasAdminScreen extends StatelessWidget {
  const ProgramasAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const service = AcademicoAdminService();
    return AdminCrudPagina<ProgramaAdmin>(
      tituloBarra: 'MCS - Gestión de programas',
      titulo: 'Gestión de programas',
      descripcion:
          'Consulta, crea, edita y elimina los programas académicos y su coordinador.',
      icono: Icons.school_outlined,
      etiquetaCrear: 'Nuevo programa',
      hintBusqueda: 'Buscar por nombre, código o coordinador',
      plural: 'programas',
      tituloVacio: 'Aún no hay programas registrados',
      tituloEliminar: 'Eliminar programa',
      mensajeCreado: 'Programa creado',
      mensajeActualizado: 'Programa actualizado',
      mensajeEliminado: 'Programa eliminado',
      mensajeYaNoExiste: 'El programa ya no existe.',
      cargar: service.programas,
      coincide: (p, q) => p.coincide(q),
      nombreEliminar: (p) => p.nombre,
      advertenciaEliminar: (p) =>
          'Se eliminará el programa ${p.codigo}. Esta acción no se puede deshacer.',
      eliminar: (p) =>
          service.api.eliminar(AcademicoAdminService.recursoProgramas, p.id),
      formulario: (p) => ProgramaFormDialog(programa: p),
      tarjeta: (p, onEditar, onEliminar) => AdminTarjeta(
        titulo: p.nombre,
        subtitulo: p.codigo.isEmpty ? null : 'Código: ${p.codigo}',
        icono: Icons.school_outlined,
        datos: [
          if (p.coordinadorNombre != null)
            AdminDato('Coordinador: ${p.coordinadorNombre}',
                icono: Icons.person_outline),
        ],
        tooltipEditar: 'Editar programa',
        tooltipEliminar: 'Eliminar programa',
        onEditar: onEditar,
        onEliminar: onEliminar,
      ),
    );
  }
}
