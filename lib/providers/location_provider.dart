import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// A provider that manages location services and updates.
///
/// This provider handles:
/// - Location permissions
/// - Current position tracking
/// - Location updates streaming
/// - Distance calculations
class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  String? _error;

  /// The current position of the device
  Position? get currentPosition => _currentPosition;

  /// Whether the provider is currently loading location data
  bool get isLoading => _isLoading;

  /// Whether the provider is currently tracking location updates
  bool get isTracking => _isTracking;

  /// The error message if any
  String? get error => _error;

  /// Initializes the location provider
  ///
  /// This method:
  /// 1. Checks and requests location permissions
  /// 2. Gets the current position
  /// 3. Updates the loading state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final request = await Geolocator.requestPermission();
        if (request == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts streaming location updates
  ///
  /// [onLocationUpdate] is called whenever the location changes
  /// Updates are filtered to occur at most every 10 meters
  void startTracking() {
    if (_isTracking) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      notifyListeners();
    });

    _isTracking = true;
    notifyListeners();
  }

  /// Stops streaming location updates
  void stopTracking() {
    _positionStream?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  /// Calculates the distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Starts streaming location updates
  ///
  /// [onLocationUpdate] is called whenever the location changes
  /// Updates are filtered to occur at most every 10 meters
  void startLocationUpdates(Function(Position) onLocationUpdate) {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      onLocationUpdate(position);
      notifyListeners();
    });
  }

  /// Stops streaming location updates
  void stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  LatLng getCurrentLatLng() {
    if (_currentPosition == null) {
      throw Exception('Location not available');
    }
    return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied';
        notifyListeners();
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error getting location: $e';
      notifyListeners();
    }
  }

  Future<void> startContinuousLocationTracking(
      [Function(Position)? onLocationUpdate]) async {
    if (_isTracking) return;

    try {
      await getCurrentLocation(); // Get initial location

      // Start tracking
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          _currentPosition = position;
          _error = null;
          _isTracking = true;
          if (onLocationUpdate != null) {
            onLocationUpdate(position);
          }
          notifyListeners();
        },
        onError: (e) {
          _error = 'Error updating location: $e';
          _isTracking = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error starting location updates: $e';
      _isTracking = false;
      notifyListeners();
    }
  }

  Future<void> stopContinuousLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }
}
