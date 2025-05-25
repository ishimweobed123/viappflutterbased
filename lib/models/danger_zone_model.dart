import 'package:cloud_firestore/cloud_firestore.dart';

class DangerZone {
  final String id;
  final String name;
  final String description;
  final GeoPoint location;
  final String severity;
  final int incidents;
  final DateTime lastReported;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  DangerZone({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.severity,
    required this.incidents,
    required this.lastReported,
    this.isActive = true,
    this.metadata,
  });

  factory DangerZone.fromJson(Map<String, dynamic> json, {String? id}) {
    return DangerZone(
      id: id ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] as GeoPoint,
      severity: json['severity'] ?? 'medium',
      incidents: json['incidents'] ?? 0,
      lastReported: (json['lastReported'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'severity': severity,
      'incidents': incidents,
      'lastReported': Timestamp.fromDate(lastReported),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  DangerZone copyWith({
    String? name,
    String? description,
    GeoPoint? location,
    String? severity,
    int? incidents,
    DateTime? lastReported,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return DangerZone(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      incidents: incidents ?? this.incidents,
      lastReported: lastReported ?? this.lastReported,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}
