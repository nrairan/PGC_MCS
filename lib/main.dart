import 'package:flutter/material.dart';
import 'package:mcs/screens/login/login.dart';
import 'package:mcs/screens/principal/menu.dart';


void main(){
  runApp(MCS());
}

class MCS extends StatelessWidget {
  const MCS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorSchemeSeed: Colors.greenAccent
      ),
      home: Login(),
    );
  }
}
