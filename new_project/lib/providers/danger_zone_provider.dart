import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visual_impaired_assistive_app/models/danger_zone_model.dart';
import 'dart:async';
import 'dart:math';

class DangerZoneProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DangerZone> _dangerZones = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _dangerZonesSubscription;

  List<DangerZone> get dangerZones => _dangerZones;
  bool get isLoading => _isLoading;

  DangerZoneProvider() {
    _initializeDangerZones();
  }

  Future<void> _initializeDangerZones() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cancel any existing subscription
      await _dangerZonesSubscription?.cancel();

      // Set up real-time listener for danger zones
      _dangerZonesSubscription = _firestore
          .collection('danger_zones')
          .where('isActive', isEqualTo: true)
          .orderBy('lastReported', descending: true)
          .snapshots()
          .listen((snapshot) {
        _dangerZones = snapshot.docs
            .map((doc) => DangerZone.fromJson(doc.data(), id: doc.id))
            .toList();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing danger zones: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDangerZone(DangerZone dangerZone) async {
    try {
      await _firestore.collection('danger_zones').add(dangerZone.toJson());
    } catch (e) {
      debugPrint('Error adding danger zone: $e');
      rethrow;
    }
  }

  Future<void> updateDangerZone(DangerZone dangerZone) async {
    try {
      await _firestore
          .collection('danger_zones')
          .doc(dangerZone.id)
          .update(dangerZone.toJson());
    } catch (e) {
      debugPrint('Error updating danger zone: $e');
      rethrow;
    }
  }

  Future<void> deleteDangerZone(String dangerZoneId) async {
    try {
      await _firestore.collection('danger_zones').doc(dangerZoneId).update({
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Error deleting danger zone: $e');
      rethrow;
    }
  }

  Future<void> reportIncident(String dangerZoneId) async {
    try {
      final dangerZone = _dangerZones.firstWhere((dz) => dz.id == dangerZoneId);
      final updatedDangerZone = dangerZone.copyWith(
        incidents: dangerZone.incidents + 1,
        lastReported: DateTime.now(),
      );
      await updateDangerZone(updatedDangerZone);
    } catch (e) {
      debugPrint('Error reporting incident: $e');
      rethrow;
    }
  }

  List<DangerZone> getNearbyDangerZones(GeoPoint location, double radiusInKm) {
    return _dangerZones.where((zone) {
      final lat1 = location.latitude;
      final lon1 = location.longitude;
      final lat2 = zone.location.latitude;
      final lon2 = zone.location.longitude;

      final distance = _calculateDistance(lat1, lon1, lat2, lon2);
      return distance <= radiusInKm;
    }).toList();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude to radians
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _haversine(dLat) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * _haversine(dLon);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  double _haversine(double rad) {
    return pow(sin(rad / 2), 2).toDouble();
  }

  @override
  void dispose() {
    _dangerZonesSubscription?.cancel();
    super.dispose();
  }
}
