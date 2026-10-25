// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURACIÓN CENTRALIZADA DE LA URL BASE
// ─────────────────────────────────────────────────────────────────────────────
//
// Cambia únicamente esta constante para apuntar a otro entorno.
// No la modifiques en tiempo de ejecución; usa distintas ramas/builds.
//
//  Entorno                    │ Valor
// ────────────────────────────┼────────────────────────────────────────
//  Emulador Android (AVD)     │ http://10.0.2.2:8000/api
//  Dispositivo físico / WiFi  │ http://192.168.X.X:8000/api
//  Web / iOS Simulator        │ http://localhost:8000/api
//  Servidor de desarrollo      │ http://127.0.0.1:8000/api  ← actual
//  Producción                  │ https://tu-dominio.com/api
//
// ⚠️  127.0.0.1 apunta al propio dispositivo que ejecuta Flutter.
//     Si Django corre en otra máquina (PC de escritorio, servidor remoto),
//     sustituye por su IP o nombre de dominio.
// ─────────────────────────────────────────────────────────────────────────────

/// URL base de la API Django. Incluye el prefijo `/api` pero SIN barra final.
const String kBaseUrl = 'http://127.0.0.1:8000/api';


/// Sesión de la API: guarda los tokens JWT para que las operaciones genéricas
/// del cliente HTTP (`listar`, `crear`, `actualizar`, `eliminar`) los adjunten
/// cuando no se pasa un `authToken` explícito.
///
/// El login asigna `token` y `refresh` tras autenticarse. El token de acceso
/// dura pocos minutos; el cliente lo renueva solo con el `refresh`.
class SesionApi {
  SesionApi._();

  /// Token de acceso (JWT) del usuario autenticado, o null si no hay sesión.
  static String? token;

  /// Token de renovación del usuario autenticado, o null si no hay sesión.
  static String? refresh;

  /// Rol del usuario autenticado ('CO', 'TI', ...), tal como lo informa la API
  /// al iniciar sesión. Solo sirve para adaptar la interfaz: los permisos y el
  /// alcance de los datos los decide siempre el servidor.
  static String? rol;

  /// true si el usuario autenticado es coordinador de programa.
  static bool get esCoordinador => rol == 'CO';

  /// true si la interfaz debe ofrecer eliminar horarios: coordinadores y TI,
  /// los únicos roles a los que la API se lo permite. Es solo presentación:
  /// el servidor verifica el permiso y el programa en cada solicitud.
  static bool get puedeEliminarHorarios => rol == 'CO' || rol == 'TI';

  /// Descarta la sesión (cierre de sesión o renovación fallida).
  static void limpiar() {
    token = null;
    refresh = null;
    rol = null;
  }
}
