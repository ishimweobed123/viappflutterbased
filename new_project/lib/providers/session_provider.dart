import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionProvider with ChangeNotifier {
  Timer? _sessionTimer;
  DateTime? _loginTime;
  Duration _sessionDuration = Duration.zero;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Duration get sessionDuration => _sessionDuration;
  String get formattedDuration {
    int hours = _sessionDuration.inHours;
    int minutes = _sessionDuration.inMinutes.remainder(60);
    int seconds = _sessionDuration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startSession(String userId) {
    _loginTime = DateTime.now();
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionDuration = DateTime.now().difference(_loginTime!);
      notifyListeners();
    });

    // Record session start in Firestore
    _firestore.collection('user_sessions').add({
      'userId': userId,
      'startTime': _loginTime,
      'status': 'active',
    });
  }

  Future<void> endSession(String userId) async {
    _sessionTimer?.cancel();
    final endTime = DateTime.now();

    // Update session record in Firestore
    final sessionQuery = await _firestore
        .collection('user_sessions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in sessionQuery.docs) {
      await doc.reference.update({
        'endTime': endTime,
        'duration': endTime.difference(_loginTime ?? endTime).inSeconds,
        'status': 'completed'
      });
    }

    _loginTime = null;
    _sessionDuration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
