import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visual_impaired_assistive_app/models/statistics_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DashboardStats? _stats;
  bool _isLoading = false;
  String _error = '';

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String get error => _error;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    try {
      setLoading(true);
      _error = '';

      // Check if user is authenticated and is admin
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        throw Exception('Insufficient permissions. Admin role required.');
      }

      // Get total users count
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.size;

      // Get active users count
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();
      final activeUsers = activeUsersSnapshot.size;

      // Get total helped count
      final helpedSnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'resolved')
          .get();
      final totalHelped = helpedSnapshot.size;

      // Get unhelped count
      final unhelpedSnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();
      final unhelped = unhelpedSnapshot.size;

      // Get failed logins count
      final failedLoginsSnapshot = await _firestore
          .collection('activities')
          .where('type', isEqualTo: 'login_failed')
          .get();
      final failedLogins = failedLoginsSnapshot.size;

      // Get danger zones
      final dangerZonesSnapshot = await _firestore
          .collection('danger_zones')
          .where('isActive', isEqualTo: true)
          .get();

      final List<DangerZone> dangerZones = dangerZonesSnapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['lastReported'] as Timestamp?;
        final createdTimestamp = data['createdAt'] as Timestamp?;
        final resolvedTimestamp = data['resolvedAt'] as Timestamp?;

        // Fix: Convert coordinates from Map to GeoPoint if needed
        GeoPoint coordinates;
        if (data['coordinates'] is GeoPoint) {
          coordinates = data['coordinates'] as GeoPoint;
        } else if (data['coordinates'] is Map) {
          final coordsMap = data['coordinates'] as Map;
          coordinates = GeoPoint(
            (coordsMap['latitude'] ?? 0.0).toDouble(),
            (coordsMap['longitude'] ?? 0.0).toDouble(),
          );
        } else {
          coordinates = const GeoPoint(0, 0);
        }

        return DangerZone(
          id: doc.id,
          location: data['location'] ?? '',
          description: data['description'] ?? '',
          severity: data['severity'] ?? 'low',
          incidents: data['incidents'] ?? 0,
          lastReported: timestamp?.toDate() ?? DateTime.now(),
          coordinates: coordinates,
          type: data['type'] ?? 'obstacle',
          affectedUsers: List<String>.from(data['affectedUsers'] ?? []),
          isActive: data['isActive'] ?? true,
          createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
          resolvedAt: resolvedTimestamp?.toDate(),
        );
      }).toList();

      // Get user reports
      final reportsSnapshot = await _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final List<UserReport> userReports = reportsSnapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;

        return UserReport(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          type: data['type'] ?? '',
          status: data['status'] ?? 'pending',
          description: data['description'] ?? '',
          timestamp: timestamp?.toDate() ?? DateTime.now(),
          location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
          deviceId: data['deviceId'],
          images: List<String>.from(data['images'] ?? []),
          isEmergency: data['isEmergency'] ?? false,
        );
      }).toList();

      // Get active user locations
      final activeLocationsSnapshot = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      final List<ActiveUser> activeUserLocations = activeLocationsSnapshot.docs
          .where((doc) => doc.data()['location'] != null)
          .map((doc) {
        final data = doc.data();
        final lastActiveTimestamp = data['lastActive'] as Timestamp?;

        return ActiveUser(
          id: doc.id,
          name: data['name'] ?? '',
          isOnline: data['isOnline'] ?? false,
          lastActive: lastActiveTimestamp?.toDate() ?? DateTime.now(),
          location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
          deviceId: data['deviceId'],
          status: data['status'] ?? 'available',
          needsAssistance: data['needsAssistance'] ?? false,
        );
      }).toList();

      // Get activity statistics
      final activityStatsSnapshot = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get();

      final Map<String, int> activityStats = {};
      for (final doc in activityStatsSnapshot.docs) {
        final type = doc.data()['type'] as String? ?? 'unknown';
        activityStats[type] = (activityStats[type] ?? 0) + 1;
      }

      _stats = DashboardStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        totalHelped: totalHelped,
        unhelped: unhelped,
        failedLogins: failedLogins,
        dangerZones: dangerZones,
        userReports: userReports,
        activeUserLocations: activeUserLocations,
        activityStats: activityStats,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading dashboard stats: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _initializeDataIfEmpty() async {
    final batch = _firestore.batch();

    // Check and initialize activities
    final activitiesSnapshot =
        await _firestore.collection('activities').limit(1).get();
    if (activitiesSnapshot.docs.isEmpty) {
      await _createInitialActivities();
    }

    // Check and initialize obstacles/danger zones
    final obstaclesSnapshot =
        await _firestore.collection('obstacles').limit(1).get();
    if (obstaclesSnapshot.docs.isEmpty) {
      await _createInitialDangerZones();
    }

    await batch.commit();
  }

  Future<void> _createInitialActivities() async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    final activities = [
      {
        'type': 'login_attempt',
        'status': 'success',
        'timestamp': now,
        'details': 'User login successful'
      },
      {
        'type': 'help_requested',
        'status': 'completed',
        'timestamp': now.subtract(const Duration(hours: 2)),
        'details': 'Navigation assistance provided'
      },
      {
        'type': 'obstacle_reported',
        'status': 'pending',
        'timestamp': now.subtract(const Duration(hours: 1)),
        'details': 'New obstacle reported'
      }
    ];

    for (final activity in activities) {
      final docRef = _firestore.collection('activities').doc();
      batch.set(docRef, activity);
    }

    await batch.commit();
  }

  Future<void> _createInitialDangerZones() async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    final dangerZones = [
      {
        'location': 'Main Street Crossing',
        'coordinates': const GeoPoint(-1.9437, 30.0594),
        'incidents': 3,
        'severity': 'high',
        'lastReported': now,
        'description': 'Busy intersection with frequent traffic'
      },
      {
        'location': 'Construction Site',
        'coordinates': const GeoPoint(-1.9442, 30.0589),
        'incidents': 2,
        'severity': 'medium',
        'lastReported': now.subtract(const Duration(days: 1)),
        'description': 'Ongoing construction work'
      }
    ];

    for (final zone in dangerZones) {
      final docRef = _firestore.collection('obstacles').doc();
      batch.set(docRef, zone);
    }

    await batch.commit();
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });
      await loadDashboardStats();
    } catch (e) {
      _error = 'Error updating user status: $e';
      debugPrint(_error);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      await loadDashboardStats();
    } catch (e) {
      _error = 'Error deleting user: $e';
      debugPrint(_error);
      rethrow;
    }
  }
}
