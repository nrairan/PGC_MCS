import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/frontend/principal/main.dart';
import 'package:mcs/frontend/login/login.dart';

void main() {
  testWidgets('MCS inicia con pantalla de Login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MCS());
    await tester.pump();

    expect(find.byType(Login), findsOneWidget);
  });
}
