import 'package:flutter/material.dart';
import 'package:mcs/frontend/barraLateral/api.dart';
//import 'package:mcs/frontend/login/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MCS());
}

class MCS extends StatefulWidget {
  const MCS({super.key});

  @override
  State<MCS> createState() => _MCSState();
}

class _MCSState extends State<MCS> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.greenAccent,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.greenAccent,
        useMaterial3: false,
      ),
      home: ApiPage(),
    );
  }
}
