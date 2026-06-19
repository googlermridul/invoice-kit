import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/features/backup/domain/usecases/backup_validator.dart';

void main() {
  group('BackupValidator', () {
    BackupValidationResult v(Map<String, dynamic>? json) => BackupValidator.validate(json);

    Map<String, dynamic> valid() => {
      'schemaVersion': InvoiceConstants.backupSchemaVersion,
      'app': 'InvoiceKit',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'businessProfile': null,
        'clients': <dynamic>[],
        'invoices': <dynamic>[],
        'quotes': <dynamic>[],
        'recurring': <dynamic>[],
        'subscriptionStatus': {'state': 'none'},
      },
    };

    test('null input is rejected', () {
      final r = v(null);
      expect(r.valid, isFalse);
      expect(r.errors.first, contains('Empty'));
    });

    test('valid minimal payload passes', () {
      final r = v(valid());
      expect(r.valid, isTrue);
      expect(r.errors, isEmpty);
    });

    test('missing schemaVersion is rejected', () {
      final payload = valid()..remove('schemaVersion');
      final r = v(payload);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('schemaVersion')), isTrue);
    });

    test('non-int schemaVersion is rejected', () {
      final payload = valid()..['schemaVersion'] = 'v1';
      final r = v(payload);
      expect(r.valid, isFalse);
    });

    test('future schemaVersion is rejected with helpful message', () {
      final payload = valid()..['schemaVersion'] = InvoiceConstants.backupSchemaVersion + 100;
      final r = v(payload);
      expect(r.valid, isFalse);
      expect(r.errors.first, contains('newer'));
    });

    test('missing exportedAt is rejected', () {
      final payload = valid()..remove('exportedAt');
      final r = v(payload);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('exportedAt')), isTrue);
    });

    test('missing data section is rejected', () {
      final payload = valid()..remove('data');
      final r = v(payload);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('data')), isTrue);
    });

    test('data must be a map, not a list', () {
      final payload = valid()..['data'] = <dynamic>[];
      final r = v(payload);
      expect(r.valid, isFalse);
    });

    test('missing inner sections are reported', () {
      final data = valid();
      (data['data'] as Map).remove('invoices');
      final r = v(data);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('invoices')), isTrue);
    });

    test('empty inner sections are allowed (a fresh account has no data)', () {
      final data = valid();
      final inner = data['data'] as Map;
      inner['clients'] = <dynamic>[];
      inner['invoices'] = <dynamic>[];
      inner['quotes'] = <dynamic>[];
      inner['recurring'] = <dynamic>[];
      final r = v(data);
      expect(r.valid, isTrue);
    });
  });
}
