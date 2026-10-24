/// Usuario tal como lo devuelve `GET /api/usuarios/`.
///
/// Solo contiene los campos que la pantalla necesita. La API nunca devuelve la
/// contraseña (es de solo escritura), así que no existe aquí.
class UsuarioAdmin {
  final int id;
  final String username;
  final String email;
  final String nombre;
  final String apellido;

  /// Código de rol de la API: CO, GC, ES o TI.
  final String rol;

  const UsuarioAdmin({
    required this.id,
    required this.username,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
  });

  /// Roles que acepta la API (`Usuario.ROLES`) con el nombre usado en la app.
  static const Map<String, String> roles = {
    'CO': 'Coordinador de Programa',
    'GC': 'Gestor del Conocimiento',
    'ES': 'Creador de oportunidades',
    'TI': 'Técnico de soporte',
  };

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) {
    String texto(dynamic v) => v?.toString() ?? '';
    final id = json['id'];
    return UsuarioAdmin(
      id: id is int ? id : int.parse(texto(id)),
      username: texto(json['username']),
      email: texto(json['email']),
      nombre: texto(json['first_name']).trim(),
      apellido: texto(json['last_name']).trim(),
      rol: texto(json['rol']),
    );
  }

  /// "Nombre Apellido", o vacío si el usuario no tiene ninguno.
  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Texto principal de la tarjeta: nombre completo o, si falta, el usuario.
  String get titulo => nombreCompleto.isNotEmpty ? nombreCompleto : username;

  /// Nombre legible del rol (vacío si la API no envió rol).
  String get rolEtiqueta => roles[rol] ?? rol;

  /// true si la consulta aparece en el nombre, usuario o correo
  /// (sin distinguir mayúsculas ni tildes). Una consulta vacía coincide.
  bool coincide(String consulta) {
    final q = normalizar(consulta.trim());
    if (q.isEmpty) return true;
    return normalizar('$nombreCompleto $username $email').contains(q);
  }

  /// Minúsculas y sin tildes, para comparar texto en español.
  static String normalizar(String s) {
    const origen = 'áàäâéèëêíìïîóòöôúùüûñ';
    const destino = 'aaaaeeeeiiiioooouuuun';
    final b = StringBuffer();
    for (final c in s.toLowerCase().split('')) {
      final i = origen.indexOf(c);
      b.write(i >= 0 ? destino[i] : c);
    }
    return b.toString();
  }
}
