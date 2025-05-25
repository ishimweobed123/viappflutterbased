import 'package:cloud_firestore/cloud_firestore.dart';

class GeoCoordinates {
  final double latitude;
  final double longitude;

  GeoCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory GeoCoordinates.fromJson(Map<String, dynamic> json) {
    return GeoCoordinates(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class DangerZone {
  final String id;
  final String location;
  final String description;
  final String severity;
  final int incidents;
  final DateTime lastReported;
  final GeoPoint coordinates;
  final String type;
  final List<String> affectedUsers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  DangerZone({
    required this.id,
    required this.location,
    required this.description,
    required this.severity,
    required this.incidents,
    required this.lastReported,
    required this.coordinates,
    required this.type,
    required this.affectedUsers,
    required this.isActive,
    required this.createdAt,
    this.resolvedAt,
  });

  factory DangerZone.fromMap(Map<String, dynamic> map, String id) {
    return DangerZone(
      id: id,
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      severity: map['severity'] ?? 'low',
      incidents: map['incidents'] ?? 0,
      lastReported: (map['lastReported'] as Timestamp).toDate(),
      coordinates: map['coordinates'] as GeoPoint,
      type: map['type'] ?? 'obstacle',
      affectedUsers: List<String>.from(map['affectedUsers'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'description': description,
      'severity': severity,
      'incidents': incidents,
      'lastReported': Timestamp.fromDate(lastReported),
      'coordinates': coordinates,
      'type': type,
      'affectedUsers': affectedUsers,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}

class UserReport {
  final String id;
  final String userId;
  final String userName;
  final String type;
  final String status;
  final String description;
  final DateTime timestamp;
  final GeoPoint location;
  final String? deviceId;
  final List<String> images;
  final bool isEmergency;

  UserReport({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.description,
    required this.timestamp,
    required this.location,
    this.deviceId,
    required this.images,
    required this.isEmergency,
  });

  factory UserReport.fromMap(Map<String, dynamic> map, String id) {
    return UserReport(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? 'pending',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      location: map['location'] as GeoPoint,
      deviceId: map['deviceId'],
      images: List<String>.from(map['images'] ?? []),
      isEmergency: map['isEmergency'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'status': status,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'deviceId': deviceId,
      'images': images,
      'isEmergency': isEmergency,
    };
  }
}

class ActiveUser {
  final String id;
  final String name;
  final bool isOnline;
  final DateTime lastActive;
  final GeoPoint location;
  final String? deviceId;
  final String status;
  final bool needsAssistance;

  ActiveUser({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.lastActive,
    required this.location,
    this.deviceId,
    required this.status,
    required this.needsAssistance,
  });

  factory ActiveUser.fromMap(Map<String, dynamic> map, String id) {
    return ActiveUser(
      id: id,
      name: map['name'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastActive: (map['lastActive'] as Timestamp).toDate(),
      location: map['location'] as GeoPoint,
      deviceId: map['deviceId'],
      status: map['status'] ?? 'available',
      needsAssistance: map['needsAssistance'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isOnline': isOnline,
      'lastActive': Timestamp.fromDate(lastActive),
      'location': location,
      'deviceId': deviceId,
      'status': status,
      'needsAssistance': needsAssistance,
    };
  }
}

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int totalHelped;
  final int unhelped;
  final int failedLogins;
  final List<DangerZone> dangerZones;
  final List<UserReport> userReports;
  final List<ActiveUser> activeUserLocations;
  final Map<String, int> activityStats;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalHelped,
    required this.unhelped,
    required this.failedLogins,
    required this.dangerZones,
    required this.userReports,
    required this.activeUserLocations,
    required this.activityStats,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      activeUsers: 0,
      totalHelped: 0,
      unhelped: 0,
      failedLogins: 0,
      dangerZones: [],
      userReports: [],
      activeUserLocations: [],
      activityStats: {},
    );
  }
}
