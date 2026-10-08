import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickerx/core/widgets/product_card.dart';
import 'package:quickerx/features/home/domain/models/product_model.dart';

void main() {
  testWidgets('ProductCard shows name, price and discount badge', (tester) async {
    const product = ProductModel(
      id: 'p1',
      name: 'Organic A2 Milk',
      imageUrl: '',
      price: 84,
      originalPrice: 105,
      meta: '1 Liter',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductCard(product: product)),
      ),
    );

    expect(find.text('Organic A2 Milk'), findsOneWidget);
    expect(find.textContaining('₹84'), findsOneWidget);
    expect(find.textContaining('% OFF'), findsOneWidget);
  });

  testWidgets('ProductCard fires onAddToCart when the add button is tapped', (tester) async {
    var tapped = false;
    const product = ProductModel(id: 'p1', name: 'Bread', imageUrl: '', price: 40);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(product: product, onAddToCart: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
