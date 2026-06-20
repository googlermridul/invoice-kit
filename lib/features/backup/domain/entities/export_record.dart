import 'package:equatable/equatable.dart';

/// A backup/restore export record.
class ExportRecord extends Equatable {
  const ExportRecord({
    required this.id,
    required this.createdAt,
    required this.sizeBytes,
    required this.itemCounts,
    this.path,
    this.label,
  });

  factory ExportRecord.fromJson(Map<String, dynamic> json) => ExportRecord(
    id: (json['id'] ?? '').toString(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    itemCounts:
        (json['itemCounts'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ) ??
        const {},
    path: json['path'] as String?,
    label: json['label'] as String?,
  );

  final String id;
  final DateTime createdAt;
  final int sizeBytes;
  final Map<String, int> itemCounts;
  final String? path;
  final String? label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'sizeBytes': sizeBytes,
    'itemCounts': itemCounts,
    'path': path,
    'label': label,
  };

  @override
  List<Object?> get props => [
    id,
    createdAt,
    sizeBytes,
    itemCounts,
    path,
    label,
  ];
}
