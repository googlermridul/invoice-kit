import 'package:invoice_kit/core/constants/invoice_constants.dart';

class BackupValidationResult {
  const BackupValidationResult({required this.valid, required this.errors});
  final bool valid;
  final List<String> errors;
}

/// Validates a backup JSON blob before import.
class BackupValidator {
  const BackupValidator._();

  static BackupValidationResult validate(Map<String, dynamic>? json) {
    final errors = <String>[];

    if (json == null) {
      return const BackupValidationResult(valid: false, errors: ['Empty backup file.']);
    }

    final version = json['schemaVersion'];
    if (version is! int) {
      errors.add('Missing or invalid schemaVersion.');
    } else if (version > InvoiceConstants.backupSchemaVersion) {
      errors.add(
        'Backup is from a newer app version (v$version). Please update InvoiceKit.',
      );
    }

    if (json['exportedAt'] is! String) {
      errors.add('Missing exportedAt timestamp.');
    }

    final payload = json['data'];
    if (payload is! Map) {
      errors.add('Missing data payload.');
      return BackupValidationResult(valid: errors.isEmpty, errors: errors);
    }

    // Soft checks — present but maybe empty.
    for (final key in const ['businessProfile', 'clients', 'invoices', 'quotes', 'recurring']) {
      if (!payload.containsKey(key)) {
        errors.add('Missing $key section.');
      }
    }

    return BackupValidationResult(valid: errors.isEmpty, errors: errors);
  }
}
