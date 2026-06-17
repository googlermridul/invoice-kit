// Integration test entry point.
// Run with: `flutter test integration_test`
import 'package:flutter_boilerplate/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and shows splash screen', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    expect(find.text('Flutter Boilerplate'), findsWidgets);
  });
}
