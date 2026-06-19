import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/extensions/string_extensions.dart';

void main() {
  group('StringX', () {
    test('isEmail', () {
      expect('jane@example.com'.isEmail, isTrue);
      expect('not-an-email'.isEmail, isFalse);
    });

    test('isPhone', () {
      expect('+1234567890'.isPhone, isTrue);
      expect('123'.isPhone, isFalse);
    });

    test('capitalized & titleCase', () {
      expect('hello'.capitalized, 'Hello');
      expect('hello world'.titleCase, 'Hello World');
    });
  });
}
