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
  bool _showQuickActions = false;
  bool _showSafetyTips = false;
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

  /// Starts listening for voice commands
  Future<void> _startListening() async {
    if (!_isListening) {
      final available = await _speechToText.initialize();
      if (available) {
        if (!mounted) return;
        final currentContext = context;
        setState(() => _isListening = true);
        await _speak('Listening for commands');

        final languageProvider =
            Provider.of<LanguageProvider>(currentContext, listen: false);
        final options = stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        );

        await _speechToText.listen(
          onResult: (result) => _handleVoiceCommand(result.recognizedWords),
          localeId: languageProvider.currentLanguage,
          listenOptions: options,
        );
      }
    }
  }

  /// Handles recognized voice commands
  ///
  /// Supported commands:
  /// - "start navigation"
  /// - "stop navigation"
  /// - "where am i"
  /// - "help"
  void _handleVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // Navigation commands
    if (lowerCommand.contains('start navigation') ||
        lowerCommand.contains('begin navigation') ||
        lowerCommand.contains('start guiding')) {
      _toggleNavigation();
    } else if (lowerCommand.contains('stop navigation') ||
        lowerCommand.contains('end navigation') ||
        lowerCommand.contains('stop guiding')) {
      _toggleNavigation();
    }
    // Location commands
    else if (lowerCommand.contains('where am i') ||
        lowerCommand.contains('my location') ||
        lowerCommand.contains('current position')) {
      _announceLocation();
    }
    // Language commands
    else if (lowerCommand.contains('change language') ||
        lowerCommand.contains('switch language')) {
      _showLanguageDialog();
    } else if (lowerCommand.contains('english')) {
      languageProvider.changeLanguage('en');
      _speak('Language changed to English');
    } else if (lowerCommand.contains('spanish') ||
        lowerCommand.contains('español')) {
      languageProvider.changeLanguage('es');
      _speak('Idioma cambiado a español');
    } else if (lowerCommand.contains('french') ||
        lowerCommand.contains('français')) {
      languageProvider.changeLanguage('fr');
      _speak('Langue changée en français');
    }
    // Help commands
    else if (lowerCommand.contains('help') ||
        lowerCommand.contains('commands') ||
        lowerCommand.contains('what can i say')) {
      _speak(
          'Available commands: start navigation, stop navigation, where am I, change language, help');
    }
    // Settings commands
    else if (lowerCommand.contains('settings') ||
        lowerCommand.contains('preferences') ||
        lowerCommand.contains('options')) {
      _showSettingsDialog();
    }
    // Emergency commands
    else if (lowerCommand.contains('emergency') ||
        lowerCommand.contains('help me') ||
        lowerCommand.contains('sos')) {
      _handleEmergency();
    }
  }

  /// Announces the user's current location using text-to-speech
  void _announceLocation() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    if (position != null) {
      _speak(
          'You are at latitude ${position.latitude.toStringAsFixed(4)}, longitude ${position.longitude.toStringAsFixed(4)}');
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
        if (await Vibration.hasVibrator() ?? false) {
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Assistant'),
        actions: [
          // Session Timer Display
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, _) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Session: ${sessionProvider.formattedDuration}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _startListening,
            tooltip: 'Voice Commands',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'Change Language',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              tooltip: 'Admin Dashboard',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final position = locationProvider.currentPosition;

          return Stack(
            children: [
              // Map view
              if (position != null)
                Positioned.fill(
                  child: _buildMap(position),
                ),

              // Quick Actions Panel
              if (_showQuickActions)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildQuickActionButton(
                            'Emergency Call',
                            Icons.emergency,
                            Colors.red,
                            () => _handleEmergency(),
                          ),
                          _buildQuickActionButton(
                            'Find Safe Route',
                            Icons.directions_walk,
                            Colors.green,
                            () {/* Implement safe route finding */},
                          ),
                          _buildQuickActionButton(
                            'Report Obstacle',
                            Icons.warning,
                            Colors.orange,
                            () => _showReportObstacleDialog(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Safety Tips Panel
              if (_showSafetyTips)
                Positioned(
                  bottom: 100,
                  left: 20,
                  child: Card(
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Safety Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSafetyTip(
                            'Stay on marked paths',
                            Icons.directions_walk,
                          ),
                          _buildSafetyTip(
                            'Keep phone charged',
                            Icons.battery_full,
                          ),
                          _buildSafetyTip(
                            'Share location with trusted contacts',
                            Icons.share_location,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Navigation controls
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        setState(() => _showQuickActions = !_showQuickActions);
                      },
                      heroTag: 'quickActions',
                      backgroundColor: Colors.blue,
                      child: Icon(_showQuickActions ? Icons.close : Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      onPressed: () {
                        setState(() => _showSafetyTips = !_showSafetyTips);
                      },
                      heroTag: 'safetyTips',
                      backgroundColor: Colors.orange,
                      child: Icon(_showSafetyTips
                          ? Icons.close
                          : Icons.tips_and_updates),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      onPressed: _toggleNavigation,
                      heroTag: 'navigation',
                      backgroundColor:
                          _isNavigating ? Colors.red : Colors.green,
                      child:
                          Icon(_isNavigating ? Icons.stop : Icons.play_arrow),
                    ),
                  ],
                ),
              ),

              // Location info
              if (position != null)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lat: ${position.latitude.toStringAsFixed(4)}'),
                          Text('Lng: ${position.longitude.toStringAsFixed(4)}'),
                          const SizedBox(height: 4),
                          Text(
                            _isNavigating
                                ? 'Navigation Active'
                                : 'Navigation Inactive',
                            style: TextStyle(
                              color: _isNavigating ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(Position position) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(position.latitude, position.longitude),
        zoom: 18.0,
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            // Handle map position changes
          }
        },
      ),
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
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 40),
        ),
      ),
    );
  }

  Widget _buildSafetyTip(String tip, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportObstacleDialog() {
    final descriptionController = TextEditingController();
    String severity = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Obstacle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: severity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) => severity = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final position =
                  Provider.of<LocationProvider>(context, listen: false)
                      .currentPosition;
              if (position != null) {
                // Implement obstacle reporting
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Obstacle reported successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
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
