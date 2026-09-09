import 'package:flutter/foundation.dart';

/// The signed-in profile.
///
/// A display profile only. This app has no backend, so there is no token to
/// hold, and no password is ever stored — see [LocalStore].
@immutable
class UserSession {
  const UserSession({
    required this.name,
    required this.email,
    this.phone = '',
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        name: json['name'] is String ? json['name'] as String : '',
        email: json['email'] is String ? json['email'] as String : '',
        phone: json['phone'] is String ? json['phone'] as String : '',
      );

  final String name;
  final String email;
  final String phone;

  /// Two letters for the avatar: initials when there is a name, otherwise the
  /// start of the email.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);

    if (parts.isEmpty) {
      return email.isEmpty ? '?' : email.substring(0, 1).toUpperCase();
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// A name to greet the shopper by, falling back to the email local part.
  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          other.name == name &&
          other.email == email &&
          other.phone == phone;

  @override
  int get hashCode => Object.hash(name, email, phone);

  @override
  String toString() => 'UserSession($email)';
}
