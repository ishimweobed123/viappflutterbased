import 'package:cloud_firestore/cloud_firestore.dart';

class UserReport {
  final String id;
  final String? userId;
  final String? userName;
  final String? type;
  final String? status;
  final String? message;
  final DateTime? timestamp;
  final String? reply;
  final DateTime? replyTimestamp;

  UserReport({
    required this.id,
    this.userId,
    this.userName,
    this.type,
    this.status,
    this.message,
    this.timestamp,
    this.reply,
    this.replyTimestamp,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      type: data['type'],
      status: data['status'],
      message: data['message'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      reply: data['reply'],
      replyTimestamp: (data['replyTimestamp'] as Timestamp?)?.toDate(),
    );
  }
}
