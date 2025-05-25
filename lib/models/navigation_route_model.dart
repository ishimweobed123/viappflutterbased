class NavigationRoute {
  final String id;
  final String name;
  final String description;
  final List<Map<String, double>> waypoints;
  final String createdBy;
  final DateTime createdAt;
  final bool isPublic;

  NavigationRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.waypoints,
    required this.createdBy,
    required this.createdAt,
    this.isPublic = false,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      waypoints: List<Map<String, double>>.from(
        json['waypoints']?.map((wp) => Map<String, double>.from(wp)) ?? [],
      ),
      createdBy: json['createdBy'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isPublic: json['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'waypoints': waypoints,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
    };
  }
}
