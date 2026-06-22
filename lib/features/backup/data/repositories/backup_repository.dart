import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_json_store.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/backup/domain/entities/export_record.dart';
import 'package:invoice_kit/features/backup/domain/usecases/backup_validator.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/recurring/domain/entities/recurring_invoice.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupPayload {
  BackupPayload({
    required this.businessProfile,
    required this.clients,
    required this.invoices,
    required this.quotes,
    required this.recurring,
    required this.subscriptionStatus,
  });

  final BusinessProfile? businessProfile;
  final List<Client> clients;
  final List<Invoice> invoices;
  final List<Quote> quotes;
  final List<RecurringInvoice> recurring;
  final SubscriptionStatus subscriptionStatus;

  Map<String, dynamic> toJson() => {
    'businessProfile': businessProfile?.toJson(),
    'clients': clients.map((c) => c.toJson()).toList(),
    'invoices': invoices.map((i) => i.toJson()).toList(),
    'quotes': quotes.map((q) => q.toJson()).toList(),
    'recurring': recurring.map((r) => r.toJson()).toList(),
    'subscriptionStatus': subscriptionStatus.toJson(),
  };

  static BackupPayload fromJson(Map<String, dynamic> json) => BackupPayload(
    businessProfile: json['businessProfile'] == null
        ? null
        : BusinessProfile.fromJson(
            Map<String, dynamic>.from(json['businessProfile'] as Map),
          ),
    clients: (json['clients'] as List<dynamic>? ?? const [])
        .map((e) => Client.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    invoices: (json['invoices'] as List<dynamic>? ?? const [])
        .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    quotes: (json['quotes'] as List<dynamic>? ?? const [])
        .map((e) => Quote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    recurring: (json['recurring'] as List<dynamic>? ?? const [])
        .map(
          (e) => RecurringInvoice.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    subscriptionStatus: json['subscriptionStatus'] == null
        ? SubscriptionStatus.initial()
        : SubscriptionStatus.fromJson(
            Map<String, dynamic>.from(json['subscriptionStatus'] as Map),
          ),
  );
}

class ImportSummary {
  ImportSummary({
    required this.clients,
    required this.invoices,
    required this.quotes,
    required this.recurring,
    required this.businessProfileImported,
  });

  final int clients;
  final int invoices;
  final int quotes;
  final int recurring;
  final bool businessProfileImported;
}

abstract class BackupRepository {
  Future<Uint8List> exportJson();
  Future<String> exportToFile();
  Future<BackupValidationResult> validate(String jsonString);
  Future<ImportSummary> importFromString(
    String jsonString, {
    bool overwrite = true,
  });
  Future<void> wipeAll();
  Future<List<ExportRecord>> history();
  Future<void> clearHistory();
}

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl({
    required HiveStorageService storage,
    required this._prefs,
    required this._subscriptionStatus,
  }) : _storage = storage {
    _clientStore = HiveJsonStore<Client>(
      storage: storage,
      boxName: HiveBoxes.clients,
      fromJson: Client.fromJson,
      toJson: (c) => c.toJson(),
    );
    _invoiceStore = HiveJsonStore<Invoice>(
      storage: storage,
      boxName: HiveBoxes.invoices,
      fromJson: Invoice.fromJson,
      toJson: (i) => i.toJson(),
    );
    _quoteStore = HiveJsonStore<Quote>(
      storage: storage,
      boxName: HiveBoxes.quotes,
      fromJson: Quote.fromJson,
      toJson: (q) => q.toJson(),
    );
    _recurringStore = HiveJsonStore<RecurringInvoice>(
      storage: storage,
      boxName: HiveBoxes.recurring,
      fromJson: RecurringInvoice.fromJson,
      toJson: (r) => r.toJson(),
    );
  }

  late final HiveJsonStore<Client> _clientStore;
  late final HiveJsonStore<Invoice> _invoiceStore;
  late final HiveJsonStore<Quote> _quoteStore;
  late final HiveJsonStore<RecurringInvoice> _recurringStore;
  final HiveStorageService _storage;
  final SharedPreferences _prefs;
  final SubscriptionStatus _subscriptionStatus;

  @override
  Future<Uint8List> exportJson() async {
    final clients = await _clientStore.all();
    final invoices = await _invoiceStore.all();
    final quotes = await _quoteStore.all();
    final recurring = await _recurringStore.all();
    final profileJson = await _readBusinessProfileJson();
    final payload = BackupPayload(
      businessProfile: profileJson,
      clients: clients,
      invoices: invoices,
      quotes: quotes,
      recurring: recurring,
      subscriptionStatus: _subscriptionStatus,
    );
    final envelope = {
      'schemaVersion': InvoiceConstants.backupSchemaVersion,
      'app': 'InvoiceKit',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': payload.toJson(),
    };
    final raw = const JsonEncoder.withIndent('  ').convert(envelope);
    return Uint8List.fromList(utf8.encode(raw));
  }

  @override
  Future<String> exportToFile() async {
    final bytes = await exportJson();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${dir.path}/${InvoiceConstants.backupFilePrefix}$stamp.json';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await _recordHistory(bytes.length, file.path);
    return path;
  }

  @override
  Future<BackupValidationResult> validate(String jsonString) async {
    try {
      final raw = jsonDecode(jsonString);
      if (raw is! Map<String, dynamic>) {
        return const BackupValidationResult(
          valid: false,
          errors: ['Backup root must be a JSON object.'],
        );
      }
      return BackupValidator.validate(raw);
    } on Exception catch (e) {
      return BackupValidationResult(valid: false, errors: ['Invalid JSON: $e']);
    }
  }

  @override
  Future<ImportSummary> importFromString(
    String jsonString, {
    bool overwrite = true,
  }) async {
    final raw = jsonDecode(jsonString);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object.');
    }
    final validation = BackupValidator.validate(raw);
    if (!validation.valid) {
      throw FormatException('Invalid backup: ${validation.errors.join('; ')}');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing data section.');
    }
    final payload = BackupPayload.fromJson(data);

    if (overwrite) {
      await _clientStore.clear();
      await _invoiceStore.clear();
      await _quoteStore.clear();
      await _recurringStore.clear();
    }

    await _clientStore.putAll(payload.clients, (c) => c.id);
    await _invoiceStore.putAll(payload.invoices, (i) => i.id);
    await _quoteStore.putAll(payload.quotes, (q) => q.id);
    await _recurringStore.putAll(payload.recurring, (r) => r.id);

    if (payload.businessProfile != null) {
      final businessBox = await _storage.openBox<dynamic>(
        'business_profile_box',
      );
      await businessBox.put('me', payload.businessProfile!.toJson());
    }

    return ImportSummary(
      clients: payload.clients.length,
      invoices: payload.invoices.length,
      quotes: payload.quotes.length,
      recurring: payload.recurring.length,
      businessProfileImported: payload.businessProfile != null,
    );
  }

  @override
  Future<void> wipeAll() async {
    await _clientStore.clear();
    await _invoiceStore.clear();
    await _quoteStore.clear();
    await _recurringStore.clear();
    final businessBox = await _storage.openBox<dynamic>('business_profile_box');
    await businessBox.clear();
  }

  @override
  Future<List<ExportRecord>> history() async {
    final raw = _prefs.getString('backup_history');
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => ExportRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on Exception catch (_) {
      return const [];
    }
  }

  @override
  Future<void> clearHistory() async {
    await _prefs.remove('backup_history');
  }

  Future<void> _recordHistory(int size, String path) async {
    final record = ExportRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      sizeBytes: size,
      itemCounts: const {},
      path: path,
    );
    final current = await history();
    final list = [record, ...current].take(20).toList();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString('backup_history', raw);
  }

  Future<BusinessProfile?> _readBusinessProfileJson() async {
    final box = await _storage.openBox<dynamic>('business_profile_box');
    final raw = box.get('me');
    if (raw is Map) {
      return BusinessProfile.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
