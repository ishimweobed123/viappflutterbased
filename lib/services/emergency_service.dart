import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:visual_impaired_assistive_app/models/statistics_model.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(initSettings);
  }

  // Send emergency alert
  Future<bool> sendEmergencyAlert({
    required String userId,
    required String userName,
    required GeoCoordinates location,
    required String description,
  }) async {
    try {
      // Create emergency report
      final report = {
        'userId': userId,
        'userName': userName,
        'type': 'emergency',
        'description': description,
        'location': GeoPoint(location.latitude, location.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'urgent',
      };

      // Add to reports collection
      final reportRef = await _firestore.collection('reports').add(report);

      // Create activity record
      await _firestore.collection('activities').add({
        'type': 'emergency_alert',
        'userId': userId,
        'reportId': reportRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Notify admins (you would implement admin notification logic here)
      await _notifyAdmins(reportRef.id, userName);

      // Show local notification to confirm
      await _showLocalNotification(
        'Emergency Alert Sent',
        'Help is on the way. Stay calm and remain where you are.',
      );

      return true;
    } catch (e) {
      debugPrint('Error sending emergency alert: $e');
      return false;
    }
  }

  // Notify admins of emergency
  Future<void> _notifyAdmins(String reportId, String userName) async {
    try {
      // Get all admin users
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      // Send notification to each admin
      for (var admin in adminSnapshot.docs) {
        await _firestore.collection('notifications').add({
          'userId': admin.id,
          'type': 'emergency',
          'title': 'Emergency Alert',
          'message': 'Emergency assistance needed for $userName',
          'reportId': reportId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      debugPrint('Error notifying admins: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'High priority channel for emergency alerts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }
}
