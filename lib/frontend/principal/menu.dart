import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mcs/frontend/materias/EcDiferencial.dart';
import 'package:mcs/frontend/materias/ProgramacionII.dart';
import 'package:mcs/frontend/barraLateral/ayuda.dart';
import 'package:mcs/frontend/barraLateral/apiHorarioPage.dart';
import 'package:mcs/frontend/funciones/notificaciones.dart';
import 'package:mcs/frontend/principal/alarmas.dart';
import 'package:mcs/frontend/barraLateral/api.dart';

import 'package:mcs/backend/api_horario.dart';

// Agrega esto al inicio de tu menu.dart
const String baseUrl =
    'http://127.0.0.1:8000/api/'; // Ajusta la URL según tu necesidad

class Menu extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const Menu({super.key, required this.onToggleTheme});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _currentIndex = 0;

  Widget _getScreenContent() {
    switch (_currentIndex) {
      case 0:
        return const Center(
          child: Icon(Icons.home, size: 70, color: Colors.grey),
        );
      case 1:
        return const Center(
          child: Icon(Icons.chat, size: 70, color: Colors.grey),
        );
      case 2:
        return Alarmas(); // ← Tu pantalla de alarmas real
      case 3:
        return Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.dark_mode),
            label: const Text('Cambiar tem'),
            onPressed: widget.onToggleTheme,
          ),
        );
      default:
        return const Center(child: Icon(Icons.help_outline, size: 70));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('MCS')),
        actions: [
          CustomButton(
            icon: Icons.notifications,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Notificaciones()),
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Neider Rairan'),
              accountEmail: const Text('nrairan@ucundinamarca.edu.co'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Text('N', style: TextStyle(fontSize: 40)),
              ),
            ),
            ListTile(
              title: const Text('SIII-Ecuaciones diferenciales'),
              leading: const Icon(Icons.calculate),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EcDiferencial()),
                );
              },
            ),

            ListTile(
              title: const Text('SII-Programación'),
              leading: const Icon(Icons.code),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProgramacionII()),
                );
              },
            ),

            ListTile(
              title: const Text('CMA'),
              leading: const Icon(Icons.web),
              onTap: () async {
                const url =
                    'https://pregrado.ucundinamarca.edu.co/login/index.php';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir la página web'),
                    ),
                  );
                }
              },
            ),

            const ListTile(title: Text('_______________')),
            ListTile(
              title: const Text('Ayuda'),
              leading: const Icon(Icons.help),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Ayuda()),
                );
              },
            ),
            ListTile(
              title: const Text('Api_horario'),
              leading: const Icon(
                Icons.help,
              ), // Corregido: Icons.help en lugar de icons.help
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ApiHorarioPage(
                          service: HorarioService(),
                        ), // Pasa el servicio como parámetro
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('API'),
              leading: const Icon(Icons.phone),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ApiPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: _getScreenContent(),
      bottomNavigationBar: GNav(
        backgroundColor:
            Theme.of(context).colorScheme.surface, // fondo de la barra
        tabBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        color: Theme.of(context).colorScheme.onSurface, // íconos inactivos
        activeColor: Theme.of(context).colorScheme.primary, // íconos activos
        selectedIndex: _currentIndex,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        tabs: const [
          GButton(icon: Icons.home, text: 'Inicio'),
          GButton(icon: Icons.chat, text: 'Chat'),
          GButton(icon: Icons.alarm, text: 'Alarmas'),
          GButton(icon: Icons.settings, text: 'Opciones'),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const CustomButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 5,
      shape: const StadiumBorder(),
      onPressed: () => onPressed!(),
      child: Icon(icon),
    );
  }
}
