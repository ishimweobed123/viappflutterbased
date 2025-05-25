import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visual_impaired_assistive_app/models/user_model.dart';
import 'package:visual_impaired_assistive_app/utils/web_auth_handler.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final WebAuthHandler _webAuth = WebAuthHandler();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  auth.User? _firebaseUser;
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  AppUser? get currentUser => _user;
  auth.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _webAuth.authStateChanges.listen((auth.User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id; // Add document ID to the data
        _user = AppUser.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _webAuth.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          data['id'] = userDoc.id;
          _user = AppUser.fromJson(data);

          // Update last login
          await _firestore.collection('users').doc(_user!.id).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });

          notifyListeners();
        }
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    try {
      setState(() => _isLoading = true);
      final userCredential = await _webAuth.createUserWithEmailAndPassword(
        email,
        password,
      );

      final user = AppUser(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        permissions: role == 'admin' ? ['read', 'write', 'admin'] : ['read'],
        lastLogin: DateTime.now(),
        preferences: {},
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set(
            user.toJson(),
          );

      // Create initial activities if admin
      if (role == 'admin') {
        await _createInitialActivities(userCredential.user!.uid);
      }

      _user = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createInitialActivities(String adminId) async {
    final batch = _firestore.batch();
    final activitiesRef = _firestore.collection('activities');

    // Create some sample activities
    final activities = [
      {
        'type': 'User Registration',
        'status': 'Completed',
        'timestamp': DateTime.now(),
        'userId': adminId,
        'details': 'Admin account created'
      },
      {
        'type': 'System Setup',
        'status': 'In Progress',
        'timestamp': DateTime.now().add(const Duration(minutes: 1)),
        'userId': adminId,
        'details': 'Initial system configuration'
      },
      {
        'type': 'Navigation Assistance',
        'status': 'Active',
        'timestamp': DateTime.now().add(const Duration(minutes: 2)),
        'userId': adminId,
        'details': 'Navigation system initialized'
      }
    ];

    for (final activity in activities) {
      final docRef = activitiesRef.doc();
      batch.set(docRef, activity);
    }

    await batch.commit();
  }

  Future<void> signOut() async {
    try {
      await _webAuth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _webAuth.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the user's profile information
  Future<void> updateUser(AppUser user) async {
    try {
      setLoading(true);
      // Update user in Firebase
      await _webAuth.currentUser?.updateDisplayName(user.name);
      await _webAuth.currentUser?.updateEmail(user.email);

      // Update local user state
      _user = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Refreshes the current user session
  Future<void> refreshSession() async {
    try {
      setLoading(true);
      final currentUser = _webAuth.currentUser;
      if (currentUser != null) {
        // Reload user data
        await currentUser.reload();

        // Update last login time
        _user = _user?.copyWith(
          lastLogin: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _webAuth.createUserWithEmailAndPassword(
        email,
        password,
      );

      final now = DateTime.now();

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'id': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'permissions': role == 'admin' ? ['read', 'write', 'admin'] : ['read'],
        'lastLogin': now.toIso8601String(),
        'preferences': {},
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
