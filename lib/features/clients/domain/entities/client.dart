import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.company,
    this.notes,
    this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    company: json['company'] as String?,
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? company;
  final String? notes;
  final DateTime? createdAt;

  Client copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? notes,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'company': company,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, name, email, phone, address, company, notes, createdAt];
}
