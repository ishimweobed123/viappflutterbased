import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_report.dart';

class UserReportProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserReport> _userReports = [];
  bool _isLoading = true;

  List<UserReport> get userReports => _userReports;
  bool get isLoading => _isLoading;

  UserReportProvider() {
    _listenToReports();
  }

  void _listenToReports() {
    _firestore
        .collection('user_reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _userReports =
          snapshot.docs.map((doc) => UserReport.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> replyToReport(String reportId, String reply) async {
    await _firestore.collection('user_reports').doc(reportId).update({
      'reply': reply,
      'status': 'resolved',
      'replyTimestamp': FieldValue.serverTimestamp(),
    });
  }
}
