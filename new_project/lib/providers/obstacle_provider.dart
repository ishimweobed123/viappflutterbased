import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visual_impaired_assistive_app/models/obstacle_model.dart';
import 'dart:math' as math;

/// A provider that manages obstacle detection and tracking.
///
/// This provider handles:
/// - Storing and retrieving obstacles
/// - Finding nearby obstacles
/// - Obstacle distance calculations
class ObstacleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Obstacle> _obstacles = [];
  bool _isLoading = false;

  /// List of all obstacles
  List<Obstacle> get obstacles => _obstacles;

  /// Whether the provider is currently loading obstacle data
  bool get isLoading => _isLoading;

  ObstacleProvider() {
    _loadObstacles();
  }

  Future<void> _loadObstacles() async {
    try {
      final snapshot = await _firestore
          .collection('obstacles')
          .where('isActive', isEqualTo: true)
          .get();

      _obstacles =
          snapshot.docs.map((doc) => Obstacle.fromJson(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading obstacles: $e');
    }
  }

  /// Adds a new obstacle to the list
  ///
  /// [obstacle] is the obstacle to add
  Future<void> addObstacle(Obstacle obstacle) async {
    try {
      await _firestore.collection('obstacles').doc(obstacle.id).set(
            obstacle.toJson(),
          );
      _obstacles.add(obstacle);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding obstacle: $e');
    }
  }

  /// Removes an obstacle from the list
  ///
  /// [obstacle] is the obstacle to remove
  Future<void> updateObstacle(Obstacle obstacle) async {
    try {
      await _firestore.collection('obstacles').doc(obstacle.id).update(
            obstacle.toJson(),
          );
      final index = _obstacles.indexWhere((o) => o.id == obstacle.id);
      if (index != -1) {
        _obstacles[index] = obstacle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating obstacle: $e');
    }
  }

  /// Removes an obstacle from the list
  ///
  /// [obstacleId] is the ID of the obstacle to remove
  Future<void> removeObstacle(String obstacleId) async {
    try {
      await _firestore.collection('obstacles').doc(obstacleId).update({
        'isActive': false,
      });
      _obstacles.removeWhere((o) => o.id == obstacleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing obstacle: $e');
    }
  }

  /// Finds obstacles within a specified radius of a location
  ///
  /// [latitude] and [longitude] specify the center point
  /// [radiusInMeters] is the search radius in meters
  /// Returns a list of obstacles sorted by distance
  Future<List<Obstacle>> getNearbyObstacles(
    double latitude,
    double longitude,
    double radiusInMeters,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final nearbyObstacles = _obstacles.where((obstacle) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          obstacle.latitude,
          obstacle.longitude,
        );
        return distance <= radiusInMeters;
      }).toList();

      // Sort by distance
      nearbyObstacles.sort((a, b) {
        final distanceA = _calculateDistance(
          latitude,
          longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          latitude,
          longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return nearbyObstacles;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates the distance between two points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final phi1 = lat1 * (math.pi / 180);
    final phi2 = lat2 * (math.pi / 180);
    final deltaPhi = (lat2 - lat1) * (math.pi / 180);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180);

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}
