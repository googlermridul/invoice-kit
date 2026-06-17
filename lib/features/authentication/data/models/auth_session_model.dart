import 'package:flutter_boilerplate/features/authentication/data/models/user_model.dart';
import 'package:flutter_boilerplate/features/authentication/domain/entities/user.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required super.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      user: UserModel.fromJson(
        json['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['user'] as Map)
            : <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': (user as UserModel).toJson(),
  };
}
