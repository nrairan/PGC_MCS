# MCS — Cliente Flutter del Gestor de Horarios (UdeC, seccional Ubaté)

Aplicación multiplataforma construida en **Flutter** que sirve como cliente del proyecto **Gestor de Horarios de Clases** de la Universidad de Cundinamarca, seccional Ubaté (Ciclo III, 2026). Permite a coordinadores y personal de TI autenticarse, administrar los datos maestros (usuarios, programas, núcleos temáticos, salones) y generar automáticamente el horario académico mediante un asistente guiado de cinco pasos.

> **Nota sobre el alcance de este repositorio.** Este repositorio contiene **únicamente el cliente Flutter**. El backend (API REST) vive en un servicio Python separado que no forma parte de este repositorio; el cliente lo consume por HTTP en `http://127.0.0.1:8000/api/`. Si buscas la lógica de generación de horarios, autenticación por token o los modelos de datos, están en ese otro servicio, no aquí.

## Estado del proyecto

El proyecto está en desarrollo activo (Ciclo III). A la fecha:

| Módulo | Estado |
|---|---|
| Login y autenticación por token (roles `CO` y `TI`) | Funcional |
| CRUD de usuarios, salones, programas y núcleos temáticos | Funcional (formularios + listados) |
| Asistente de generación automática de horario (5 pasos) | Funcional, conectado a la API |
| Visualización del horario generado | Funcional |
| Panel de TI (indicadores, gráficas, actividad reciente) | Interfaz de maqueta — los datos mostrados son de ejemplo, aún no se conectan a la API |
| Historial de horarios / Ruta de aprendizaje | Pantallas de marcador de posición (placeholder), sin lógica |
| Chat de soporte (`chat.dart`) | Archivo vacío, sin implementar |
| Acceso de gestores del conocimiento (`GC`) y creadores de oportunidades (`ES`) | La API los distingue por rol, pero la pantalla de login **solo enruta los roles `CO` y `TI`**; los demás reciben "Rol no autorizado" |
| Notificaciones | Pantalla estática ("Sin notificaciones"), sin lógica de push ni de recordatorios |

## Arquitectura
Cliente Flutter (este repo) ── HTTP/JSON ──▶ API REST en Python (repo separado, puerto 8000)
│
├── android / ios / web / windows / linux / macos (targets de compilación de Flutter)
└── lib/
├── backend/ → clientes HTTP y pantallas de listado que consumen la API
└── frontend/ → pantallas, formularios y widgets de la interfaz


La comunicación es HTTP simple con `package:http`; no hay gestor de estado (Provider/Riverpod/Bloc) ni almacenamiento local persistente: cada pantalla mantiene su propio estado con `setState`.

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) con Dart `^3.7.2` (usa `flutter --version` para verificar).
- Un editor con soporte Flutter (VS Code o Android Studio).
- El backend del proyecto corriendo localmente en `http://127.0.0.1:8000/` (o accesible en red), ya que la app no tiene modo offline ni datos de prueba embebidos.

## Instalación y ejecución

```bash
git clone https://github.com/nrairan/PGC_MCS.git
cd PGC_MCS
flutter pub get
```

Crea un archivo `.env` en la raíz del proyecto (actualmente vacío/no versionado; se carga con `flutter_dotenv` en el arranque aunque ninguna pantalla lee todavía una variable desde él — ver [Problemas conocidos](#problemas-conocidos-y-deuda-técnica)):

```bash
touch .env
```

**Importante:** el proyecto no tiene `lib/main.dart` en la raíz — el punto de entrada real es `lib/frontend/principal/main.dart`. Debes indicarlo explícitamente al ejecutar o compilar:

```bash
flutter run -t lib/frontend/principal/main.dart
```

Para un dispositivo o plataforma específica:

```bash
flutter run -t lib/frontend/principal/main.dart -d chrome     # Web
flutter run -t lib/frontend/principal/main.dart -d windows    # Windows
flutter run -t lib/frontend/principal/main.dart -d <device-id> # Android/iOS
```

### Apuntar la app al backend correcto

La URL base de la API está definida por separado en varios archivos (`lib/backend/api_horario.dart`, `lib/frontend/login/login.dart`, cada `formulario_*.dart`, `lib/frontend/TI-Rol/ayudas/crearHorario.dart`, `lib/frontend/TI-Rol/horarios.dart`, etc.), no en un único lugar centralizado. Por defecto todas apuntan a `http://127.0.0.1:8000/api/`. Según dónde ejecutes el backend, cambia manualmente esas constantes:

| Entorno de ejecución | URL a usar |
|---|---|
| Emulador Android (AVD) | `http://10.0.2.2:8000/api/` |
| Dispositivo físico en la misma red Wi-Fi | `http://<IP-local-del-PC>:8000/api/` (obtén la IP con `ipconfig` / `ifconfig`) |
| Web o simulador iOS | `http://localhost:8000/api/` |
| Producción | `https://tu-dominio.com/api/` |

## Estructura de carpetas
lib/
├── backend/
│ ├── api_horario.dart # Cliente HTTP genérico de horarios
│ └── resultados_api/ # Listados que consumen la API (usuarios, programas, asignaturas, matrículas)
└── frontend/
├── principal/main.dart # Punto de entrada real de la app (MaterialApp, tema claro/oscuro)
├── login/login.dart # Autenticación por token y enrutamiento por rol (CO, TI)
├── barraLateral/
│ ├── api.dart # Panel principal del rol Coordinador (CO)
│ ├── ayuda.dart # Pantalla de contacto/soporte
│ └── chat.dart # Placeholder vacío, sin implementar
├── TI-Rol/
│ ├── ti.dart # Panel principal del rol TI (datos de ejemplo)
│ ├── horarios.dart # Visualización del horario generado
│ ├── ayudas/ # crearHorario.dart (asistente de 5 pasos), salonesList.dart, historial.dart, ruta_aprendizaje.dart
│ └── funciones/ # registros.dart, graficas.dart (placeholders)
├── formularios/ # Alta de usuario, salón, programa, núcleo temático y matrícula
├── funciones/notificaciones.dart # Pantalla estática de notificaciones
└── widgets/ # menu_lateral.dart (nav. rol CO), lateral_ti.dart (nav. rol TI)


## Roles del sistema

La API distingue cuatro roles (`rol=CO|TI|GC|ES`), pero el cliente hoy solo enruta dos de ellos desde el login:

| Rol | Código | Pantalla de destino tras el login | Estado en el cliente |
|---|---|---|---|
| Coordinador de programa | `CO` | `ApiPage` (panel de coordinación) | Implementado |
| Personal de TI | `TI` | `PanelTI` (panel de administración) | Implementado |
| Gestor del conocimiento | `GC` | — | La API lo soporta (`fetchGestores` filtra por `rol=GC`); el login no lo enruta aún |
| Creador de oportunidades (estudiante) | `ES` | — | La API lo soporta (`formulario_matricula.dart` filtra por `rol=ES`); el login no lo enruta aún |

## Pantallas y funcionalidades principales

| Pantalla | Archivo | Descripción |
|---|---|---|
| Login | `login/login.dart` | Autenticación contra `POST /api/token/`, búsqueda del usuario y enrutamiento por rol |
| Panel de Coordinación | `barraLateral/api.dart` | Resumen y accesos a usuarios, núcleos temáticos, salones y programas |
| Panel de TI | `TI-Rol/ti.dart` | Indicadores, accesos a registros/gráficas/logs (datos de ejemplo) |
| Asistente de generación de horario | `TI-Rol/ayudas/crearHorario.dart` | Wizard de 5 pasos: semestre → núcleos temáticos → gestores/materias → descansos → generación; guarda cada bloque con `POST /api/horarios/` |
| Visualización del horario | `TI-Rol/horarios.dart` | Consulta `GET /api/horarios/por_semestre/` y muestra el horario por día |
| Listados (usuarios, asignaturas, programas, salones, matrículas) | `backend/resultados_api/*.dart`, `TI-Rol/ayudas/salonesList.dart` | Listas con estado de carga y manejo de error |
| Formularios de alta | `formularios/formulario_*.dart` | Creación de usuario, salón, programa, núcleo temático y matrícula |
| Ayuda | `barraLateral/ayuda.dart` | Datos de contacto de soporte |

## Endpoints consumidos por el cliente

| Método | Endpoint | Usado en |
|---|---|---|
| `POST` | `/api/token/` | `login/login.dart` |
| `GET` | `/api/usuarios/` | `login/login.dart`, `backend/resultados_api/usuarios_list.dart` |
| `GET` | `/api/usuarios/?rol=GC` | `backend/api_horario.dart`, `TI-Rol/ayudas/crearHorario.dart` |
| `GET` | `/api/usuarios/?rol=CO` | `formularios/formulario_programa.dart` |
| `GET` | `/api/usuarios/?rol=ES` | `formularios/formulario_matricula.dart` |
| `POST` | `/api/usuarios/` | `formularios/formulario_usuario.dart` |
| `GET` | `/api/asignaturas/` | `backend/resultados_api/asignaturas_list.dart`, `crearHorario.dart`, `formulario_matricula.dart` |
| `POST` | `/api/asignaturas/` | `formularios/formulario_asignatura.dart` |
| `GET` | `/api/programa/` | `backend/resultados_api/programas_list.dart`, `formulario_asignatura.dart` |
| `POST` | `/api/programa/` | `formularios/formulario_programa.dart` |
| `GET` | `/api/salones/` | `TI-Rol/ayudas/salonesList.dart` |
| `POST` | `/api/salones/` | `formularios/formulario_salon.dart` |
| `GET` | `/api/matricula/`, `POST` | `formularios/formulario_matricula.dart` |
| `GET` | `/api/matriculas/` | `backend/resultados_api/matriculas_list.dart` |
| `GET` | `/api/horarios/por_semestre/?semestre=` | `TI-Rol/horarios.dart`, `backend/api_horario.dart` |
| `POST` | `/api/horarios/` | `TI-Rol/ayudas/crearHorario.dart` |

> Nota: existen pequeñas inconsistencias de nomenclatura heredadas del backend (`/api/programa/` en singular junto a `/api/programas/` mencionado en documentación previa, `/api/matricula/` junto a `/api/matriculas/`). Conviene unificarlas del lado del backend antes de la entrega final.

## Pruebas

```bash
flutter test
```

El único archivo de pruebas (`test/widget_test.dart`) es la plantilla por defecto de Flutter (el "contador"); como la app ya no tiene ese contador, **la prueba fallará tal como está**. Debe sustituirse por pruebas de widget reales (por ejemplo, sobre `Login`, `AsignaturasListPage` o el asistente de generación de horario) antes de usarla como criterio de aceptación.

## Problemas conocidos y deuda técnica

- **Sin `lib/main.dart` en la raíz:** cualquier herramienta o IDE que asuma la convención estándar de Flutter debe configurarse para apuntar a `lib/frontend/principal/main.dart`.
- **URL del backend duplicada en más de diez archivos:** un cambio de entorno (local → LAN → producción) obliga a editar cada archivo manualmente. Se recomienda centralizarla en una sola clase de configuración leída desde `.env` con `flutter_dotenv` (la dependencia ya está instalada, pero hoy solo se llama a `dotenv.load()` sin leer ninguna clave).
- **Clase `UsuarioForm` duplicada:** `formularios/formulario_usuario.dart`, `formulario_horario.dart` y `formulario_notificacion.dart` definen los tres una clase `UsuarioForm`/`_UsuarioFormState`. Solo la de `formulario_usuario.dart` está en uso; los otros dos archivos no se importan desde ningún lugar y deberían eliminarse o renombrarse.
- **`barraLateral/chat.dart` está vacío.**
- **Roles `GC` y `ES` no enrutados desde el login**, pese a que la API y varios formularios ya los contemplan.
- **Panel de TI con datos de ejemplo** ("Sin datos", gráficas simuladas, log con fechas fijas) — pendiente de conectar a la API real.
- **No existe archivo `LICENSE`** en el repositorio, aunque la documentación previa mencionaba licencia MIT.

## Autores

**Neider Alejandro Rairan Salas**
GitHub: [nrairan](https://github.com/nrairan) · Correo: nrairan@ucundinamarca.edu.co

**Jimmi Alejandro Arévalo Contreras**
GitHub: JimmiArevalo · Correo: jimmiaarevalo@ucundinamarca.edu.co

Universidad de Cundinamarca, seccional Ubaté — Programa de Ingeniería de Sistemas y Computación.


  
