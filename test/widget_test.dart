import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robo_car_controller/main.dart';

void main() {
  testWidgets('RoboCar App Test', (WidgetTester tester) async {

    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);

  });
}