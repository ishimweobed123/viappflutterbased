import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:visual_impaired_assistive_app/models/statistics_model.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final double _dangerZoneRadius = 100.0; // meters

  // Stream of all active danger zones
  Stream<List<DangerZone>> getDangerZones() {
    return _firestore
        .collection('dangerZones')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DangerZone.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of all active user locations
  Stream<List<ActiveUser>> getActiveUsers() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActiveUser.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of all active devices
  Stream<QuerySnapshot> getActiveDevices() {
    return _firestore
        .collection('devices')
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  // Update user's location
  Future<void> updateUserLocation(String userId, Position position) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Check for nearby danger zones
      await _checkNearbyDangerZones(userId, position);
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  // Check if user is near any danger zones
  Future<void> _checkNearbyDangerZones(
      String userId, Position userPosition) async {
    try {
      final dangerZones = await _firestore
          .collection('dangerZones')
          .where('isActive', isEqualTo: true)
          .get();

      for (final zone in dangerZones.docs) {
        final data = zone.data();
        final zoneLocation = data['coordinates'] as GeoPoint;

        final distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          zoneLocation.latitude,
          zoneLocation.longitude,
        );

        if (distance <= _dangerZoneRadius) {
          // Create alert for user
          await _createDangerZoneAlert(userId, zone.id, distance);
        }
      }
    } catch (e) {
      debugPrint('Error checking nearby danger zones: $e');
    }
  }

  // Create an alert when user is near a danger zone
  Future<void> _createDangerZoneAlert(
      String userId, String zoneId, double distance) async {
    try {
      await _firestore.collection('alerts').add({
        'userId': userId,
        'dangerZoneId': zoneId,
        'distance': distance,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'danger_zone_proximity',
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error creating danger zone alert: $e');
    }
  }

  // Create a new user report
  Future<void> createUserReport({
    required String userId,
    required String userName,
    required String type,
    required String description,
    required Position location,
    required bool isEmergency,
    List<String> images = const [],
    String? deviceId,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'userId': userId,
        'userName': userName,
        'type': type,
        'status': 'pending',
        'description': description,
        'location': GeoPoint(location.latitude, location.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'deviceId': deviceId,
        'images': images,
        'isEmergency': isEmergency,
      });

      if (isEmergency) {
        await _createEmergencyAlert(userId, location);
      }
    } catch (e) {
      debugPrint('Error creating user report: $e');
      rethrow;
    }
  }

  // Create an emergency alert
  Future<void> _createEmergencyAlert(String userId, Position location) async {
    try {
      await _firestore.collection('alerts').add({
        'userId': userId,
        'location': GeoPoint(location.latitude, location.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'urgent',
        'type': 'emergency',
        'isRead': false,
      });

      // Notify nearby users or emergency services
      await _notifyNearbyUsers(location);
    } catch (e) {
      debugPrint('Error creating emergency alert: $e');
    }
  }

  // Notify nearby users about an emergency
  Future<void> _notifyNearbyUsers(Position emergencyLocation) async {
    try {
      final nearbyUsers = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      for (final user in nearbyUsers.docs) {
        final userLocation = user.data()['location'] as GeoPoint;

        final distance = Geolocator.distanceBetween(
          emergencyLocation.latitude,
          emergencyLocation.longitude,
          userLocation.latitude,
          userLocation.longitude,
        );

        if (distance <= 1000) {
          // Within 1km
          await _firestore.collection('notifications').add({
            'userId': user.id,
            'type': 'nearby_emergency',
            'distance': distance,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      debugPrint('Error notifying nearby users: $e');
    }
  }

  // Update device status
  Future<void> updateDeviceStatus(
    String deviceId, {
    required bool isOnline,
    required int batteryLevel,
    Position? location,
  }) async {
    try {
      final data = {
        'isOnline': isOnline,
        'batteryLevel': batteryLevel,
        'lastSeen': FieldValue.serverTimestamp(),
      };

      if (location != null) {
        data['location'] = GeoPoint(location.latitude, location.longitude);
      }

      await _firestore.collection('devices').doc(deviceId).update(data);

      // Create alert if battery is low
      if (batteryLevel <= 20) {
        await _createLowBatteryAlert(deviceId, batteryLevel);
      }
    } catch (e) {
      debugPrint('Error updating device status: $e');
    }
  }

  // Create a low battery alert
  Future<void> _createLowBatteryAlert(String deviceId, int batteryLevel) async {
    try {
      await _firestore.collection('alerts').add({
        'deviceId': deviceId,
        'batteryLevel': batteryLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'status': batteryLevel <= 10 ? 'urgent' : 'warning',
        'type': 'low_battery',
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error creating low battery alert: $e');
    }
  }
}
