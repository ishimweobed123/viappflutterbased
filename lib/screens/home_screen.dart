import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visual_impaired_assistive_app/providers/location_provider.dart';
import 'package:visual_impaired_assistive_app/providers/obstacle_provider.dart';
import 'package:visual_impaired_assistive_app/providers/language_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:visual_impaired_assistive_app/providers/auth_provider.dart';
import 'package:visual_impaired_assistive_app/providers/session_provider.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:visual_impaired_assistive_app/services/emergency_service.dart';
import 'package:visual_impaired_assistive_app/services/screen_reader_service.dart';
import 'package:visual_impaired_assistive_app/models/statistics_model.dart';
import 'package:visual_impaired_assistive_app/models/user_model.dart';
import 'package:visual_impaired_assistive_app/providers/danger_zone_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A screen that provides navigation assistance for visually impaired users.
///
/// This screen includes:
/// - Real-time location tracking
/// - Obstacle detection and alerts
/// - Voice commands for hands-free operation
/// - Text-to-speech feedback
/// - Haptic feedback for obstacles
/// - Map visualization
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isNavigating = false;
  String _lastSpokenText = '';
  final MapController _mapController = MapController();
  final EmergencyService _emergencyService = EmergencyService();
  final ScreenReaderService _screenReader = ScreenReaderService();

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeSpeech();
    _setupAccessibility();
    _initializeServices();

    // Start session tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<SessionProvider>(context, listen: false)
            .startSession(authProvider.user!.id);
      }
    });
  }

  /// Initializes the text-to-speech engine with appropriate settings
  Future<void> _initializeTts() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    await _flutterTts.setLanguage(languageProvider.currentLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Initializes the speech recognition engine
  Future<void> _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
      onError: (error) => debugPrint('Speech recognition error: $error'),
      debugLogging: true,
      finalTimeout: const Duration(seconds: 3),
    );
  }

  /// Sets up accessibility features including screen reader support
  void _setupAccessibility() {
    SystemChannels.accessibility.setMessageHandler((dynamic message) async {
      if (message is Map && message['message'] != null) {
        await _speak(message['message'] as String);
      }
      return null;
    });
  }

  /// Speaks the given text using the text-to-speech engine
  ///
  /// Prevents duplicate announcements by checking against [_lastSpokenText]
  Future<void> _speak(String text) async {
    if (text != _lastSpokenText) {
      await _flutterTts.speak(text);
      _lastSpokenText = text;
    }
  }

  /// Toggles navigation mode on/off
  ///
  /// When enabled:
  /// - Starts location updates
  /// - Enables obstacle detection
  /// - Provides audio and haptic feedback
  Future<void> _toggleNavigation() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    setState(() {
      _isNavigating = !_isNavigating;
    });

    if (_isNavigating) {
      await _speak(
          'Navigation started. I will alert you of any obstacles ahead.');
      await Vibration.vibrate(duration: 200);
      locationProvider.startContinuousLocationTracking(_handleLocationUpdate);
    } else {
      await _speak('Navigation stopped');
      await Vibration.vibrate(duration: 100);
      locationProvider.stopContinuousLocationTracking();
    }
  }

  /// Handles location updates and obstacle detection
  ///
  /// Checks for nearby obstacles and provides alerts when:
  /// - Obstacles are detected within 50 meters
  /// - Obstacles are within 10 meters (immediate alert)
  void _handleLocationUpdate(Position position) async {
    final obstacleProvider =
        Provider.of<ObstacleProvider>(context, listen: false);
    final obstacles = await obstacleProvider.getNearbyObstacles(
      position.latitude,
      position.longitude,
      50, // 50 meters radius
    );

    if (obstacles.isNotEmpty) {
      final nearestObstacle = obstacles.first;
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        nearestObstacle.latitude,
        nearestObstacle.longitude,
      );

      if (distance < 10) {
        // Alert if obstacle is within 10 meters
        await _speak(
            'Warning! Obstacle detected ${distance.toStringAsFixed(1)} meters ahead');
        await Vibration.vibrate(duration: 500, amplitude: 128);
      }
    }
  }

  /// Calculates the distance between two points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  languageProvider.availableLanguages.entries.map((entry) {
                return ListTile(
                  title: Text(entry.value),
                  selected: entry.key == languageProvider.currentLanguage,
                  onTap: () {
                    languageProvider.changeLanguage(entry.key);
                    Navigator.pop(context);
                    _speak('Language changed to ${entry.value}');
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Language'),
              trailing: Consumer<LanguageProvider>(
                builder: (context, languageProvider, _) =>
                    Text(languageProvider.currentLanguageName),
              ),
              onTap: _showLanguageDialog,
            ),
            ListTile(
              title: const Text('Speech Rate'),
              trailing: const Icon(Icons.speed),
              onTap: () => _showSpeechRateDialog(),
            ),
            ListTile(
              title: const Text('Vibration Settings'),
              trailing: const Icon(Icons.vibration),
              onTap: () => _showVibrationSettingsDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeechRateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speech Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: 0.5,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: 'Speech Rate',
              onChanged: (value) async {
                await _flutterTts.setSpeechRate(value);
                _speak('Speech rate set to ${(value * 100).round()}%');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVibrationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vibration Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Vibration Intensity'),
              trailing: const Icon(Icons.vibration),
              onTap: () async {
                await Vibration.vibrate(duration: 500, amplitude: 128);
                _speak('Vibration intensity test');
              },
            ),
            ListTile(
              title: const Text('Vibration Pattern'),
              trailing: const Icon(Icons.pattern),
              onTap: () async {
                await Vibration.vibrate(pattern: [500, 1000, 500]);
                _speak('Vibration pattern test');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeServices() async {
    await _emergencyService.initialize();
    await _screenReader.initialize();
  }

  /// Handles emergency situations
  Future<void> _handleEmergency() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final AppUser? currentUser = authProvider.currentUser;

    if (currentUser == null) {
      await _screenReader.speak('Please sign in to use emergency services',
          interrupt: true);
      return;
    }

    if (locationProvider.currentPosition == null) {
      await _screenReader.speak('Getting your location. Please wait.',
          interrupt: true);
      await locationProvider.getCurrentLocation();
    }

    if (locationProvider.currentPosition != null) {
      final position = locationProvider.currentPosition!;
      final success = await _emergencyService.sendEmergencyAlert(
        userId: currentUser.id,
        userName: currentUser.name,
        location: GeoCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        description: 'Emergency assistance needed at current location',
      );

      if (success) {
        await _screenReader.readEmergencyStatus('Emergency Alert Sent',
            'Your emergency alert has been sent. Help is on the way.');
        // Vibrate in SOS pattern (... --- ...)
        if (await Vibration.hasVibrator()) {
          for (var i = 0; i < 3; i++) {
            for (var j = 0; j < 3; j++) {
              await Vibration.vibrate(duration: j < 3 ? 200 : 500);
              await Future.delayed(const Duration(milliseconds: 200));
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      } else {
        await _screenReader.readEmergencyStatus(
          'Alert Failed',
          'Could not send emergency alert. Please try again or call emergency services directly.',
        );
      }
    } else {
      await _screenReader.readEmergencyStatus(
        'Location Unavailable',
        'Could not determine your location. Please ensure location services are enabled.',
      );
    }
  }

  // Modern user dashboard layout, matching admin dashboard style
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          _buildUserSidebar(user),
          Expanded(
            child: Column(
              children: [
                _buildUserHeader(user),
                Expanded(child: _buildUserDashboardBody(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fix ListTile and SizedBox usage, and ensure all widget parameters are correct
  Widget _buildUserSidebar(AppUser? user) {
    return Container(
      width: 220,
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          SizedBox(height: 32),
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            user?.name ?? 'User',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 32),
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.white70),
            title: Text('Dashboard', style: TextStyle(color: Colors.white70)),
            selected: true,
            selectedTileColor: Color(0xFF263238),
            onTap: null,
          ),
          ListTile(
            leading: Icon(Icons.map, color: Colors.white70),
            title: Text('My Location', style: TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.of(context).pushNamed('/my_location');
            },
          ),
          ListTile(
            leading: Icon(Icons.warning, color: Colors.white70),
            title:
                Text('Danger Zones', style: TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.of(context).pushNamed('/danger_zones');
            },
          ),
          ListTile(
            leading: Icon(Icons.report, color: Colors.white70),
            title: Text('My Reports', style: TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.of(context).pushNamed('/my_reports');
            },
          ),
          Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserHeader(AppUser? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'User Dashboard',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.blueGrey),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueGrey),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
          ),
          SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.blue[200],
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDashboardBody(AppUser? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserStatCards(user),
          SizedBox(height: 24),
          _buildUserMapSection(),
          SizedBox(height: 24),
          _buildUserReportsSection(user),
          SizedBox(height: 24),
          _buildUserDangerZonesSection(),
        ],
      ),
    );
  }

  Widget _buildUserStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatCards(AppUser? user) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchUserStats(user),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'devices': 0, 'reports': 0, 'dangerZones': 0};
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUserStatCard('My Devices', stats['devices'].toString(),
                Icons.device_hub, Colors.blue),
            _buildUserStatCard('Reports', stats['reports'].toString(),
                Icons.report, Colors.orange),
            _buildUserStatCard('Danger Zones', stats['dangerZones'].toString(),
                Icons.warning, Colors.red),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _fetchUserStats(AppUser? user) async {
    if (user == null) return {'devices': 0, 'reports': 0, 'dangerZones': 0};
    final firestore = FirebaseFirestore.instance;
    final devicesSnap = await firestore
        .collection('devices')
        .where('userId', isEqualTo: user.id)
        .get();
    final reportsSnap = await firestore
        .collection('reports')
        .where('userId', isEqualTo: user.id)
        .get();
    final dangerZonesSnap = await firestore
        .collection('danger_zones')
        .where('affectedUsers', arrayContains: user.id)
        .get();
    return {
      'devices': devicesSnap.size,
      'reports': reportsSnap.size,
      'dangerZones': dangerZonesSnap.size,
    };
  }

  Widget _buildUserMapSection() {
    return Card(
      elevation: 4,
      child: SizedBox(
        height: 300,
        child: Consumer2<LocationProvider, DangerZoneProvider>(
          builder: (context, locationProvider, dangerZoneProvider, _) {
            final position = locationProvider.currentPosition;
            final dangerZones = dangerZoneProvider.dangerZones;
            if (position == null) {
              return const Center(child: Text('Location not available'));
            }
            return _buildMapWithDangerZones(position, dangerZones);
          },
        ),
      ),
    );
  }

  Widget _buildUserReportsSection(AppUser? user) {
    if (user == null) {
      return const SizedBox();
    }
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: user.id)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data as dynamic).docs.isEmpty) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('My Reports',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('You have not submitted any reports yet.'),
                ],
              ),
            ),
          );
        }
        final docs = (snapshot.data as dynamic).docs;
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Reports',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...docs.map<Widget>((doc) => ListTile(
                      leading: const Icon(Icons.report, color: Colors.orange),
                      title: Text(doc['type'] ?? 'Report'),
                      subtitle: Text(doc['description'] ?? ''),
                      trailing: Text(doc['status'] ?? 'pending'),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserDangerZonesSection() {
    return Consumer<DangerZoneProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.dangerZones.isEmpty) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Nearby Danger Zones',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('No danger zones nearby.'),
                ],
              ),
            ),
          );
        }
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nearby Danger Zones',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...provider.dangerZones.take(5).map((zone) => ListTile(
                      leading: Icon(Icons.warning,
                          color: zone.severity == 'high'
                              ? Colors.red
                              : zone.severity == 'medium'
                                  ? Colors.orange
                                  : Colors.yellow),
                      title: Text(zone.name),
                      subtitle: Text(zone.description),
                      trailing: Text(zone.severity.toUpperCase()),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add the missing _buildMapWithDangerZones method for the user dashboard
  Widget _buildMapWithDangerZones(Position position, List dangerZones) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(position.latitude, position.longitude),
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'You are here',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...dangerZones.map((zone) => Marker(
                  point:
                      LatLng(zone.location.latitude, zone.location.longitude),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.warning,
                    color: zone.severity == 'high'
                        ? Colors.red
                        : zone.severity == 'medium'
                            ? Colors.orange
                            : Colors.yellow,
                    size: 32,
                  ),
                )),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<SessionProvider>(context, listen: false)
          .endSession(authProvider.user!.id);
    }
    _flutterTts.stop();
    _speechToText.stop();
    _screenReader.dispose();
    super.dispose();
  }
}
