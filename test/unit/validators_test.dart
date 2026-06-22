import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/validators/validators.dart';

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

    test('phoneLenient allows empty and validates format', () {
      expect(Validators.phoneLenient(null), isNull);
      expect(Validators.phoneLenient(''), isNull);
      expect(Validators.phoneLenient('   '), isNull);
      expect(Validators.phoneLenient('+1 555 123 4567'), isNull);
      expect(Validators.phoneLenient('abc'), isNotNull);
      expect(Validators.phoneLenient('123'), isNotNull);
    });

    test('nonNegativeNumber rejects negatives and non-numbers', () {
      expect(Validators.nonNegativeNumber(null, fieldName: 'Tax'), isNotNull);
      expect(Validators.nonNegativeNumber('', fieldName: 'Tax'), isNotNull);
      expect(Validators.nonNegativeNumber('abc', fieldName: 'Tax'), isNotNull);
      expect(Validators.nonNegativeNumber('-1', fieldName: 'Tax'), isNotNull);
      expect(Validators.nonNegativeNumber('0', fieldName: 'Tax'), isNull);
      expect(Validators.nonNegativeNumber('12.5', fieldName: 'Tax'), isNull);
    });

    test('positiveNumber requires strictly greater than zero', () {
      expect(Validators.positiveNumber(null, fieldName: 'Qty'), isNotNull);
      expect(Validators.positiveNumber('', fieldName: 'Qty'), isNotNull);
      expect(Validators.positiveNumber('0', fieldName: 'Qty'), isNotNull);
      expect(Validators.positiveNumber('-1', fieldName: 'Qty'), isNotNull);
      expect(Validators.positiveNumber('0.5', fieldName: 'Qty'), isNull);
      expect(Validators.positiveNumber('3', fieldName: 'Qty'), isNull);
    });
  });
}
