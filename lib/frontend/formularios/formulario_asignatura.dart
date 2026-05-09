import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mcs/frontend/widgets/lateral_ti.dart';

// ─────────────────────────────────────────────
// COLORES
// ─────────────────────────────────────────────
const Color kVerde      = Color(0xFF1A6433);
const Color kVerdeFondo = Color(0xFFF0F4F1);
const Color kGrisTexto  = Color(0xFF555555);
const Color kGrisHint   = Color(0xFF9E9E9E);

// ─────────────────────────────────────────────
// SEMESTRES
// ─────────────────────────────────────────────
const List<String> kSemestresForm = [
  '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
];

class AsignaturaForm extends StatefulWidget {
  const AsignaturaForm({super.key});

  @override
  State<AsignaturaForm> createState() => _AsignaturaFormState();
}

class _AsignaturaFormState extends State<AsignaturaForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codigoController   = TextEditingController();
  final TextEditingController _nombreController   = TextEditingController();
  final TextEditingController _creditosController = TextEditingController();
  final TextEditingController _searchController   = TextEditingController();

  int?    _programaSeleccionado;
  String? _semestreSeleccionado;

  List<dynamic> _programas        = [];
  bool          _cargandoProgramas = true;
  bool          _guardando         = false;
  String?       _errorCarga;

  static const String _apiUrl       = 'http://127.0.0.1:8000/api/asignaturas/';
  static const String _programasUrl = 'http://127.0.0.1:8000/api/programa/';

  @override
  void initState() {
    super.initState();
    _cargarProgramas();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _creditosController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProgramas() async {
    setState(() { _cargandoProgramas = true; _errorCarga = null; });
    try {
      final res = await http.get(Uri.parse(_programasUrl));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _programas        = json.decode(utf8.decode(res.bodyBytes));
          _cargandoProgramas = false;
        });
      } else {
        setState(() {
          _errorCarga        = 'Error ${res.statusCode} al cargar programas';
          _cargandoProgramas = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _errorCarga = 'Sin conexión con el servidor'; _cargandoProgramas = false; });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final res = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo':   _codigoController.text.trim(),
          'nombre':   _nombreController.text.trim(),
          'programa': _programaSeleccionado,
          'creditos': int.parse(_creditosController.text.trim()),
          'semestre': _semestreSeleccionado,
          'gestores': [],
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        _snack('Núcleo temático creado exitosamente', ok: true);
        _resetForm();
      } else {
        String det = res.body;
        try { det = jsonDecode(res.body).toString(); } catch (_) {}
        _snack('Error: $det', ok: false);
      }
    } catch (e) {
      if (mounted) _snack('Error de conexión: $e', ok: false);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _codigoController.clear();
    _nombreController.clear();
    _creditosController.clear();
    setState(() { _programaSeleccionado = null; _semestreSeleccionado = null; });
  }

  void _snack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: ok ? kVerde : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: kVerdeFondo,
      appBar: _buildAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LateralTi(),
          Expanded(child: _buildCuerpo()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      //backgroundColor: kVerde,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Crear Núcleo Temático',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 360,
            height: 36,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar clases, gestores o salones',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCuerpo() {
    if (_cargandoProgramas) {
      return const Center(
        child: CircularProgressIndicator(color: kVerde),
      );
    }
    if (_errorCarga != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFC62828), size: 48),
            const SizedBox(height: 12),
            Text(_errorCarga!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarProgramas,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kVerde, foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      // Mismo padding lateral generoso que en la imagen
      padding: const EdgeInsets.fromLTRB(48, 36, 48, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Nombre ─────────────────────────────────────────────
                _LineField(
                  controller: _nombreController,
                  label: 'Nombre del núcleo temático',
                  validar: (v) => v == null || v.trim().isEmpty
                      ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 28),

                // ── Código del programa (texto) ────────────────────────
                _LineField(
                  controller: _codigoController,
                  label: 'Código',
                  validar: (v) => v == null || v.trim().isEmpty
                      ? 'El código es obligatorio' : null,
                ),
                const SizedBox(height: 28),

                // ── Créditos ───────────────────────────────────────────
                _LineField(
                  controller: _creditosController,
                  label: 'Créditos',
                  teclado: TextInputType.number,
                  validar: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obligatorio';
                    if (int.tryParse(v.trim()) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── Programa (dropdown) ────────────────────────────────
                _LineDropdown<int>(
                  hint: 'Nombre del programa',
                  value: _programaSeleccionado,
                  items: _programas.map<DropdownMenuItem<int>>((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(
                        p['nombre'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: kGrisTexto),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _programaSeleccionado = v),
                  validar: (v) => v == null ? 'Selecciona un programa' : null,
                ),
                const SizedBox(height: 28),

                // ── Semestre (dropdown) ────────────────────────────────
                _LineDropdown<String>(
                  hint: 'Semestre',
                  value: _semestreSeleccionado,
                  items: kSemestresForm.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      'Semestre $s',
                      style: const TextStyle(fontSize: 14, color: kGrisTexto),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _semestreSeleccionado = v),
                  validar: (v) => v == null ? 'Selecciona un semestre' : null,
                ),
                const SizedBox(height: 40),

                // ── Botón Registrar ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _submitForm,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Registrar',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          letterSpacing: 0.3),
                    ),
                    style: ElevatedButton.styleFrom(
                      //backgroundColor: kVerde,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Limpiar ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton.icon(
                    onPressed: _guardando ? null : _resetForm,
                    icon: const Icon(Icons.clear, size: 15),
                    label: const Text('Limpiar formulario'),
                    style: TextButton.styleFrom(
                      foregroundColor: kGrisHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CAMPO DE TEXTO — solo línea inferior
// ─────────────────────────────────────────────
class _LineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType teclado;
  final String? Function(String?)? validar;

  const _LineField({
    required this.controller,
    required this.label,
    this.teclado = TextInputType.text,
    this.validar,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      validator: validar,
      style: const TextStyle(fontSize: 15, color: kGrisTexto),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: kGrisHint),
        floatingLabelStyle: const TextStyle(
            fontSize: 12, color: kVerde, fontWeight: FontWeight.w500),
        // Sin borde completo, solo línea inferior
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: kVerde, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        filled: false,
        contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DROPDOWN — solo línea inferior
// ─────────────────────────────────────────────
class _LineDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validar;

  const _LineDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validar,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validar,
      isExpanded: true,
      style: const TextStyle(fontSize: 15, color: kGrisTexto),
      hint: Text(hint, style: const TextStyle(fontSize: 14, color: kGrisHint)),
      decoration: const InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 1.2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: kVerde, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: false,
        contentPadding: EdgeInsets.only(bottom: 8, top: 4),
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down, color: kGrisHint, size: 22),
    );
  }
}