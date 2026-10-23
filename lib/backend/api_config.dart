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
