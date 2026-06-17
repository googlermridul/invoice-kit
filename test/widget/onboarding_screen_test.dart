import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/theme/app_theme.dart';
import 'package:flutter_boilerplate/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Onboarding screen renders three pages and a CTA', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Production-ready'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
