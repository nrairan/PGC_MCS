import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';
import 'package:mcs/frontend/widgets/graficos/graficos_ti.dart';

class graficasScreen extends StatelessWidget {
  const graficasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficas'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const LateralTi(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: const [
                  Text(
                    'Gráficas del Sistema',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: GraficoUsuariosPorRol()),
                      SizedBox(width: 16),
                      Expanded(child: GraficoSalonesPorEdificio()),
                    ],
                  ),
                  SizedBox(height: 20),
                  GraficoActividadSemanal(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
