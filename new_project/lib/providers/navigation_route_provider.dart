import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visual_impaired_assistive_app/models/navigation_route_model.dart';

class NavigationRouteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NavigationRoute> _routes = [];

  List<NavigationRoute> get routes => _routes;

  NavigationRouteProvider() {
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final snapshot = await _firestore.collection('routes').get();
      _routes = snapshot.docs
          .map((doc) => NavigationRoute.fromJson(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading routes: $e');
    }
  }

  Future<void> addRoute(NavigationRoute route) async {
    try {
      await _firestore.collection('routes').doc(route.id).set(
            route.toJson(),
          );
      _routes.add(route);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding route: $e');
    }
  }

  Future<void> updateRoute(NavigationRoute route) async {
    try {
      await _firestore.collection('routes').doc(route.id).update(
            route.toJson(),
          );
      final index = _routes.indexWhere((r) => r.id == route.id);
      if (index != -1) {
        _routes[index] = route;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating route: $e');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).delete();
      _routes.removeWhere((r) => r.id == routeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting route: $e');
    }
  }

  List<NavigationRoute> getPublicRoutes() {
    return _routes.where((route) => route.isPublic).toList();
  }

  List<NavigationRoute> getUserRoutes(String userId) {
    return _routes.where((route) => route.createdBy == userId).toList();
  }
}
