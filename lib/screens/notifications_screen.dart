import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visual_impaired_assistive_app/providers/notification_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:visual_impaired_assistive_app/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                      ),
                      if (!notification.read)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.read
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(notification.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: notification.read,
                        onChanged: (bool? value) {
                          if (value != null) {
                            notificationProvider.markAsRead(notification.id);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _handleNotificationTap(context, notification);
                    if (!notification.read) {
                      notificationProvider.markAsRead(notification.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'obstacle':
        return Icons.warning;
      case 'navigation':
        return Icons.directions;
      case 'system':
        return Icons.info;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'obstacle':
        return Colors.orange;
      case 'navigation':
        return Colors.blue;
      case 'system':
        return Colors.green;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(
      BuildContext context, AppNotification notification) {
    switch (notification.type) {
      case 'obstacle':
        Navigator.pushNamed(context, '/obstacle-details',
            arguments: notification.data);
        break;
      case 'navigation':
        Navigator.pushNamed(context, '/navigation',
            arguments: notification.data);
        break;
      case 'emergency':
        Navigator.pushNamed(context, '/emergency-details',
            arguments: notification.data);
        break;
      case 'system':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;
  int _vibrationDuration = 500;
  int _vibrationAmplitude = 128;
  bool _hasCustomVibrator = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _hasCustomVibrator = await Vibration.hasCustomVibrationsSupport() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SwitchListTile(
                title: const Text('Obstacle Notifications'),
                subtitle: const Text('Receive alerts about obstacles'),
                value: notificationProvider.obstacleNotificationsEnabled,
                onChanged: (value) {
                  notificationProvider.setObstacleNotificationsEnabled(value);
                },
              ),
              SwitchListTile(
                title: const Text('Navigation Notifications'),
                subtitle: const Text('Receive navigation updates'),
                value: notificationProvider.navigationNotificationsEnabled,
                onChanged: (value) {
                  notificationProvider.setNavigationNotificationsEnabled(value);
                },
              ),
              SwitchListTile(
                title: const Text('System Notifications'),
                subtitle: const Text('Receive system updates'),
                value: notificationProvider.systemNotificationsEnabled,
                onChanged: (value) {
                  notificationProvider.setSystemNotificationsEnabled(value);
                },
              ),
              const Divider(),
              ExpansionTile(
                title: const Text('Sound Settings'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Volume'),
                        Slider(
                          value: _volume,
                          onChanged: (value) async {
                            setState(() => _volume = value);
                            await _flutterTts.setVolume(value);
                            await _flutterTts.speak('Testing volume');
                          },
                        ),
                        const Text('Pitch'),
                        Slider(
                          value: _pitch,
                          onChanged: (value) async {
                            setState(() => _pitch = value);
                            await _flutterTts.setPitch(value);
                            await _flutterTts.speak('Testing pitch');
                          },
                        ),
                        const Text('Speech Rate'),
                        Slider(
                          value: _rate,
                          onChanged: (value) async {
                            setState(() => _rate = value);
                            await _flutterTts.setSpeechRate(value);
                            await _flutterTts.speak('Testing speech rate');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Vibration Settings'),
                children: [
                  if (_hasCustomVibrator) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Duration (milliseconds)'),
                          Slider(
                            min: 100,
                            max: 1000,
                            divisions: 9,
                            value: _vibrationDuration.toDouble(),
                            label: _vibrationDuration.toString(),
                            onChanged: (value) {
                              setState(
                                  () => _vibrationDuration = value.toInt());
                              Vibration.vibrate(
                                duration: _vibrationDuration,
                                amplitude: _vibrationAmplitude,
                              );
                            },
                          ),
                          const Text('Intensity'),
                          Slider(
                            min: 1,
                            max: 255,
                            value: _vibrationAmplitude.toDouble(),
                            label: _vibrationAmplitude.toString(),
                            onChanged: (value) {
                              setState(
                                  () => _vibrationAmplitude = value.toInt());
                              Vibration.vibrate(
                                duration: _vibrationDuration,
                                amplitude: _vibrationAmplitude,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Your device does not support custom vibration patterns.',
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
