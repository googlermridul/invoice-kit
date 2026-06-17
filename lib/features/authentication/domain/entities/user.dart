import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.phone,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? phone;
  final bool emailVerified;

  bool get isFullyVerified => emailVerified;

  User copyWith({
    String? name,
    String? avatarUrl,
    String? phone,
    bool? emailVerified,
  }) =>
      User(
        id: id,
        email: email,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        emailVerified: emailVerified ?? this.emailVerified,
      );

  @override
  List<Object?> get props => [id, email, name, avatarUrl, phone, emailVerified];
}

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
