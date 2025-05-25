import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final List<String> permissions;
  final DateTime lastLogin;
  final Map<String, dynamic> preferences;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.lastLogin,
    required this.preferences,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    List<String>? permissions,
    DateTime? lastLogin,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final lastLoginData = json['lastLogin'];
    final DateTime lastLogin;

    if (lastLoginData is Timestamp) {
      lastLogin = lastLoginData.toDate();
    } else if (lastLoginData is String) {
      lastLogin = DateTime.parse(lastLoginData);
    } else {
      lastLogin = DateTime.now();
    }

    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      permissions: List<String>.from(json['permissions'] ?? []),
      lastLogin: lastLogin,
      preferences: json['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'permissions': permissions,
      'lastLogin': Timestamp.fromDate(lastLogin),
      'preferences': preferences,
    };
  }
}
