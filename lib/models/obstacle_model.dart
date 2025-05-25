class Obstacle {
  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime timestamp;
  final String reportedBy;
  final bool isActive;

  Obstacle({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.timestamp,
    required this.reportedBy,
    this.isActive = true,
  });

  factory Obstacle.fromJson(Map<String, dynamic> json) {
    return Obstacle(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      reportedBy: json['reportedBy'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'reportedBy': reportedBy,
      'isActive': isActive,
    };
  }
}
