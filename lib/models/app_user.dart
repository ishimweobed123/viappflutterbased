import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isOnline;
  final DateTime lastActive;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isOnline = false,
    DateTime? lastActive,
  }) : lastActive = lastActive ?? DateTime.now();

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isOnline': isOnline,
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }
}
