import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/theme/app_theme.dart';

void main() {
  testWidgets('Material theme builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: Text('Hello boilerplate'))),
      ),
    );
    expect(find.text('Hello boilerplate'), findsOneWidget);
  });
}
