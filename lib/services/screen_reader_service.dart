import 'package:flutter_tts/flutter_tts.dart';
import 'package:visual_impaired_assistive_app/models/statistics_model.dart';

class ScreenReaderService {
  final FlutterTts _flutterTts = FlutterTts();
  String _lastSpokenText = '';
  bool _isInitialized = false;

  // Initialize TTS engine
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    }
  }

  // Speak text with optional interrupt
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_isInitialized) await initialize();

    if (interrupt || text != _lastSpokenText) {
      if (interrupt) {
        await _flutterTts.stop();
      }
      await _flutterTts.speak(text);
      _lastSpokenText = text;
    }
  }

  // Stop speaking
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // Read user report details
  Future<void> readUserReport(UserReport report) async {
    final text = '''
      Report from ${report.userName}
      Type: ${report.type}
      Status: ${report.status}
      Description: ${report.description}
      Reported on: ${report.timestamp.toString()}
    ''';
    await speak(text, interrupt: true);
  }

  // Read danger zone details
  Future<void> readDangerZone(DangerZone zone) async {
    final text = '''
      Danger zone at ${zone.location}
      Severity: ${zone.severity}
      Number of incidents: ${zone.incidents}
      Last reported: ${zone.lastReported.toString()}
    ''';
    await speak(text, interrupt: true);
  }

  // Read active user details
  Future<void> readActiveUser(ActiveUser user) async {
    final text = '''
      User ${user.name}
      Status: ${user.isOnline ? 'Online' : 'Offline'}
      Last active: ${user.lastActive.toString()}
    ''';
    await speak(text, interrupt: true);
  }

  // Read statistics summary
  Future<void> readStatistics(DashboardStats stats) async {
    final text = '''
      Dashboard Summary:
      Total Users: ${stats.totalUsers}
      Active Users: ${stats.activeUsers}
      People Helped: ${stats.totalHelped}
      Pending Help Requests: ${stats.unhelped}
      Active Danger Zones: ${stats.dangerZones.length}
      Recent Reports: ${stats.userReports.length}
    ''';
    await speak(text, interrupt: true);
  }

  // Read emergency status
  Future<void> readEmergencyStatus(String status, String details) async {
    final text = '''
      Emergency Status: $status
      $details
    ''';
    await speak(text, interrupt: true);
  }

  // Dispose TTS engine
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
