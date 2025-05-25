import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:visual_impaired_assistive_app/models/notification_model.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AppNotification> _notifications = [];
  bool _obstacleNotificationsEnabled = true;
  bool _navigationNotificationsEnabled = true;
  bool _systemNotificationsEnabled = true;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  List<AppNotification> get notifications => _notifications;
  bool get obstacleNotificationsEnabled => _obstacleNotificationsEnabled;
  bool get navigationNotificationsEnabled => _navigationNotificationsEnabled;
  bool get systemNotificationsEnabled => _systemNotificationsEnabled;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _initializeNotifications();
    _loadSettings();
    _initializeMessaging();
  }

  Future<void> _initializeNotifications() async {
    // Cancel any existing subscription
    await _notificationSubscription?.cancel();

    // Set up real-time listener for notifications
    _notificationSubscription = _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('notifications').get();
      if (doc.exists) {
        final data = doc.data()!;
        _obstacleNotificationsEnabled = data['obstacle'] ?? true;
        _navigationNotificationsEnabled = data['navigation'] ?? true;
        _systemNotificationsEnabled = data['system'] ?? true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _initializeMessaging() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNewNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Handle background messages
    debugPrint('Handling background message: ${message.messageId}');
  }

  Future<void> _handleNewNotification(RemoteMessage message) async {
    final notification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      message: message.notification?.body ?? '',
      type: message.data['type'] ?? 'system',
      timestamp: DateTime.now(),
      data: message.data,
      read: false,
    );

    await addNotification(notification);
  }

  Future<void> setObstacleNotificationsEnabled(bool value) async {
    _obstacleNotificationsEnabled = value;
    await _updateSettings();
    notifyListeners();
  }

  Future<void> setNavigationNotificationsEnabled(bool value) async {
    _navigationNotificationsEnabled = value;
    await _updateSettings();
    notifyListeners();
  }

  Future<void> setSystemNotificationsEnabled(bool value) async {
    _systemNotificationsEnabled = value;
    await _updateSettings();
    notifyListeners();
  }

  Future<void> _updateSettings() async {
    try {
      await _firestore.collection('settings').doc('notifications').set({
        'obstacle': _obstacleNotificationsEnabled,
        'navigation': _navigationNotificationsEnabled,
        'system': _systemNotificationsEnabled,
      });
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).set(
            notification.toJson(),
          );
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore.collection('notifications').get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Future<void> sendEmergencyNotification(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      setLoading(true);

      // Get emergency contacts
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final emergencyContacts =
          userDoc.data()?['emergencyContacts'] as List<dynamic>? ?? [];

      // Send notification to each emergency contact
      for (final contact in emergencyContacts) {
        final contactId = contact['id'] as String;
        final contactDoc =
            await _firestore.collection('users').doc(contactId).get();
        final contactToken = contactDoc.data()?['fcmToken'] as String?;

        if (contactToken != null) {
          await _messaging.sendMessage(
            to: contactToken,
            data: {
              'type': 'emergency',
              'userId': userId,
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'title': 'Emergency Alert',
              'body':
                  'User needs assistance at location: $latitude, $longitude',
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending emergency notification: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
