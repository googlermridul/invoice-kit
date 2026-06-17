import 'package:flutter_boilerplate/core/validators/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('jane@example.com'), isNull);
    });

    test('password enforces length + diversity', () {
      expect(Validators.password('Aa1!'), isNotNull); // too short
      expect(Validators.password('alllowercase1!'), isNotNull); // no upper
      expect(Validators.password('ALLUPPERCASE1!'), isNotNull); // no lower
      expect(Validators.password('NoDigits!'), isNotNull); // no digit
      expect(Validators.password('GoodPass1!'), isNull);
    });

    test('confirmPassword', () {
      expect(Validators.confirmPassword(null, 'x'), isNotNull);
      expect(Validators.confirmPassword('y', 'x'), isNotNull);
      expect(Validators.confirmPassword('x', 'x'), isNull);
    });
  });
}
