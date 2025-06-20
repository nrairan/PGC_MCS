📘 PGC_MCS - Plataforma de Gestión Curricular
PGC_MCS (Plataforma de Gestión Curricular Multi-Componente para la Universidad de Cundinamarca, seccional Ubaté) es un sistema modular desarrollado en Django destinado a la gestión de:

Asignación de horarios

Administración de salones

Control de matrículas

Envío de notificaciones

Configuración de usuarios y programas académicos

🚀 Características destacadas
🔐 Autenticación basada en JWT

🧠 Gestión de usuarios por roles: coordinador, estudiante, gestor del conocimiento.

📚 CRUD completo para:

Usuarios

Programas académicos

Asignaturas

Salones

Horarios

Matrículas

🔔 Notificaciones por usuario

📦 API RESTful preparada para integrarse con las aplicaciones Flutter o frontend web.

🧩 Arquitectura modular y extensible.

🗂 Estructura de carpetas
de texto plano
Copiar
Editar
PGC_MCS/
├── api/ # Serializadores y vistas de la API REST
│ └── urls.py
├── core/ # Modelos principales como Usuario, Programa, Notificación
│ └── models.py
├── horarios/ # Modelos de Horario y Salón
├── matriculas/ # Matrículas y lógica de inscripción
├── config/ # Configuración principal del proyecto
│ ├── settings.py
│ └── urls.py
├── templates/ # HTML (opcional)
├── static/ # Archivos estáticos (CSS, JS, imágenes)
├── tests/ # Pruebas unitarias y de integración
├── Manage.py
└── README.md # Documentación
🔧 Instalación local
Clona el repositorio:

bash
Copiar
Editar
git clone https://github.com/nrairan/PGC_MCS.git
cd PGC_MCS
Crea un entorno virtual:

bash
Copiar
Editar
python -m venv venv
source venv/bin/activate # Linux/Mac
venv\Scripts\activate # Windows
Instala las dependencias:

bash
Copiar
Editar
pip install -r requisitos.txt
Crea un archivo .env:

env
Copiar
Editar
DEBUG=True
SECRET_KEY=tu_clave_secreta
DATABASE_URL=postgres://usuario:contraseña @localhost :5432/pgc_mcs
Aplica migraciones y ejecuta el servidor:

bash
Copiar
Editar
python Manage.py migrar
python Manage.py Runserver
🛠 API Endpoints principales
Recurso Método Endpoint Descripción
Usuarios GET /api/usuarios/ Listado de usuarios
Programas POST /api/programas/ Crear nuevo programa
Horarios GET /api/horarios/ Consultar horarios
Matrículas POST /api/matriculas/ Registrar matrícula
Notificaciones GET /api/notificaciones/ Listar notificaciones del usuario
Login POST /api/token/ Autenticación por JWT

🧪 Pruebas
Se recomienda usar pytest o unittest:

bash
Copiar
Editar
python enable.py test
👥 Roles del sistema
Rol Permisos
Coordinador Administra programas, asignaturas, horarios y usuarios.
Estudiante Consulta horarios, matrícula y recibe notificaciones.
Gestor del conocimiento Visualiza y sugiere mejoras curriculares.

📱 Frontend
La API puede ser consumida por cualquier cliente HTTP, incluida una aplicación Flutter. Se recomienda usar autenticación con JWT para asegurar la comunicación.

📌 Próximos pasos
Integración con calendario institucional.

Informes PDF de matrícula y horarios.

Tablero de mando para coordinadores.

🤝 Contribuciones
Haz fork del repositorio

Crea una rama nueva: git checkout -b feature/mi-feature

Haz tus cambios

Realizar push en tu rama: git push origin feature/mi-feature

Abrir una solicitud de extracción

📄 Licencia
Este proyecto está bajo licencia MIT. Consulta el archivo LICENCIA para más información.

📬 Contactos
Neider Rairan
GitHub: nrairan
Correo: nrairan@ucundinamarca.edu.co

Jimmi Arévalo
GitHub: Jimmi Arévalo
Correo: jimmiaarevalo@ucundinamarca.edu .co
 
 
