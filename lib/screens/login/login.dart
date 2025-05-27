import 'package:flutter/material.dart';
import 'package:mcs/screens/principal/menu.dart';

class Login extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const Login({super.key, required this.onToggleTheme});


  @override
  Widget build(BuildContext context) {
    final size=MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('MCS'),),),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.1,
                vertical: size.height* 0.05),

              child: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'e-mail',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700
                  )
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(left: size.width * .1, right: size.width * 0.1, bottom: size.height * 0.05),
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'password',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700
                  )
                ),
                onChanged: (value) {},
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Menu(onToggleTheme: onToggleTheme),
                  ),
                );
              },
              child: const Text('Iniciar sesión'),
            )
          ],
        )
      )
    );
  }

}