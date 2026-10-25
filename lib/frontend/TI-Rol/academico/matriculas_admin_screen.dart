import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/TI-Rol/academico/matricula_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Gestión de matrículas del rol TI.
class MatriculasAdminScreen extends StatelessWidget {
  const MatriculasAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const service = AcademicoAdminService();
    return AdminCrudPagina<MatriculaAdmin>(
      tituloBarra: 'MCS - Gestión de matrículas',
      titulo: 'Gestión de matrículas',
      descripcion:
          'Consulta, crea, edita y elimina las matrículas de los estudiantes en cada asignatura.',
      icono: Icons.how_to_reg_outlined,
      etiquetaCrear: 'Nueva matrícula',
      hintBusqueda: 'Buscar por estudiante, asignatura, programa o semestre',
      plural: 'matrículas',
      tituloVacio: 'Aún no hay matrículas registradas',
      tituloEliminar: 'Eliminar matrícula',
      mensajeCreado: 'Matrícula creada',
      mensajeActualizado: 'Matrícula actualizada',
      mensajeEliminado: 'Matrícula eliminada',
      mensajeYaNoExiste: 'La matrícula ya no existe.',
      cargar: service.matriculas,
      coincide: (m, q) => m.coincide(q),
      nombreEliminar: (m) =>
          '${m.estudianteNombre ?? 'Estudiante #${m.estudianteId}'} en '
          '${m.asignaturaNombre ?? 'asignatura #${m.asignaturaId}'}',
      advertenciaEliminar: (m) =>
          'Se eliminará la matrícula del semestre ${m.semestre}. Esta acción no se puede deshacer.',
      eliminar: (m) =>
          service.api.eliminar(AcademicoAdminService.recursoMatriculas, m.id),
      formulario: (m) => MatriculaFormDialog(matricula: m),
      tarjeta: (m, onEditar, onEliminar) => AdminTarjeta(
        titulo: m.estudianteNombre ?? 'Estudiante #${m.estudianteId}',
        subtitulo: m.estudianteCorreo,
        icono: Icons.how_to_reg_outlined,
        datos: [
          AdminDato(
            m.asignaturaNombre == null
                ? 'Asignatura #${m.asignaturaId}'
                : 'Asignatura: ${m.asignaturaNombre}'
                    '${(m.asignaturaCodigo ?? '').isEmpty ? '' : ' (${m.asignaturaCodigo})'}',
            icono: Icons.menu_book_outlined,
          ),
          if (m.programaNombre != null)
            AdminDato('Programa: ${m.programaNombre}',
                icono: Icons.school_outlined),
        ],
        etiquetas: [if (m.semestre.isNotEmpty) 'Semestre ${m.semestre}'],
        tooltipEditar: 'Editar matrícula',
        tooltipEliminar: 'Eliminar matrícula',
        onEditar: onEditar,
        onEliminar: onEliminar,
      ),
    );
  }
}
