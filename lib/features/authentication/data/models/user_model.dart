import 'package:flutter_boilerplate/features/authentication/domain/entities/user.dart';

/// JSON-friendly mirror of [User]. To use json_serializable codegen, add
/// `@JsonSerializable()` and the `User.fromJson` factory.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.avatarUrl,
    super.phone,
    super.emailVerified = false,
  });

  factory UserModel.fromEntity(User user) => UserModel(
    id: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    phone: user.phone,
    emailVerified: user.emailVerified,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    email: json['email']?.toString() ?? '',
    name: json['name']?.toString(),
    avatarUrl: (json['avatar'] ?? json['avatarUrl'])?.toString(),
    phone: json['phone']?.toString(),
    emailVerified: json['emailVerified'] == true || json['verified'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (name != null) 'name': name,
    if (avatarUrl != null) 'avatar': avatarUrl,
    if (phone != null) 'phone': phone,
    'emailVerified': emailVerified,
  };
}
