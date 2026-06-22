import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/theme/app_theme.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen renders three pages and a CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to InvoiceKit'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
