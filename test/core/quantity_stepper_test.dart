import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickerx/core/widgets/quantity_stepper.dart';

void main() {
  testWidgets('QuantityStepper shows ADD button when quantity is 0', (tester) async {
    var incremented = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: QuantityStepper(quantity: 0, onIncrement: () => incremented = true, onDecrement: () {}),
      ),
    ));

    expect(find.text('ADD'), findsOneWidget);
    await tester.tap(find.text('ADD'));
    expect(incremented, isTrue);
  });

  testWidgets('QuantityStepper shows +/- controls and current quantity when > 0', (tester) async {
    var newQuantity = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: QuantityStepper(
          quantity: 3,
          onIncrement: () => newQuantity = 4,
          onDecrement: () => newQuantity = 2,
        ),
      ),
    ));

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(newQuantity, 4);
    await tester.tap(find.byIcon(Icons.remove_rounded));
    expect(newQuantity, 2);
  });
}
