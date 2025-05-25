import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider that manages language settings for the app.
///
/// This provider handles:
/// - Language selection
/// - Language persistence
/// - Text-to-speech language settings
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  String _currentLanguage = 'en';
  bool _isLoading = false;

  /// Available languages in the app
  final Map<String, String> _availableLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ar': 'العربية',
  };

  /// The currently selected language code
  String get currentLanguage => _currentLanguage;

  /// The currently selected language name
  String get currentLanguageName =>
      _availableLanguages[_currentLanguage] ?? 'English';

  /// Whether the provider is currently loading language settings
  bool get isLoading => _isLoading;

  /// List of available language codes
  List<String> get availableLanguageCodes => _availableLanguages.keys.toList();

  /// Map of language codes to their display names
  Map<String, String> get availableLanguages => _availableLanguages;

  LanguageProvider() {
    _loadLanguage();
  }

  /// Loads the saved language preference
  Future<void> _loadLanguage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null &&
          _availableLanguages.containsKey(savedLanguage)) {
        _currentLanguage = savedLanguage;
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the current language
  ///
  /// [languageCode] is the code of the language to switch to
  Future<void> changeLanguage(String languageCode) async {
    if (!_availableLanguages.containsKey(languageCode)) {
      throw Exception('Unsupported language: $languageCode');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _currentLanguage = languageCode;
    } catch (e) {
      debugPrint('Error changing language: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets the translation for a given key in the current language
  String getTranslation(String key) {
    final translations = {
      'en': {
        'navigation_started':
            'Navigation started. I will alert you of any obstacles ahead.',
        'navigation_stopped': 'Navigation stopped',
        'obstacle_detected':
            'Warning! Obstacle detected {distance} meters ahead',
        'location_announcement': 'You are at latitude {lat}, longitude {lng}',
        'emergency_activated':
            'Emergency mode activated. Sending your location to emergency contacts.',
        'help_on_way':
            'Your location has been shared with emergency contacts. Help is on the way.',
        'location_error': 'Unable to share location. Please try again.',
        'listening': 'Listening for commands',
        'available_commands':
            'Available commands: start navigation, stop navigation, where am I, change language, help',
      },
      'es': {
        'navigation_started':
            'Navegación iniciada. Te alertaré de cualquier obstáculo por delante.',
        'navigation_stopped': 'Navegación detenida',
        'obstacle_detected':
            '¡Advertencia! Obstáculo detectado a {distance} metros por delante',
        'location_announcement': 'Estás en latitud {lat}, longitud {lng}',
        'emergency_activated':
            'Modo de emergencia activado. Enviando tu ubicación a contactos de emergencia.',
        'help_on_way':
            'Tu ubicación ha sido compartida con contactos de emergencia. La ayuda está en camino.',
        'location_error':
            'No se puede compartir la ubicación. Por favor, inténtalo de nuevo.',
        'listening': 'Escuchando comandos',
        'available_commands':
            'Comandos disponibles: iniciar navegación, detener navegación, dónde estoy, cambiar idioma, ayuda',
      },
      'fr': {
        'navigation_started':
            'Navigation démarrée. Je vous alerterai de tout obstacle devant vous.',
        'navigation_stopped': 'Navigation arrêtée',
        'obstacle_detected':
            'Attention ! Obstacle détecté à {distance} mètres devant',
        'location_announcement':
            'Vous êtes à la latitude {lat}, longitude {lng}',
        'emergency_activated':
            'Mode d\'urgence activé. Envoi de votre position aux contacts d\'urgence.',
        'help_on_way':
            'Votre position a été partagée avec les contacts d\'urgence. L\'aide est en chemin.',
        'location_error':
            'Impossible de partager la position. Veuillez réessayer.',
        'listening': 'Écoute des commandes',
        'available_commands':
            'Commandes disponibles : démarrer la navigation, arrêter la navigation, où suis-je, changer de langue, aide',
      },
    };

    return translations[_currentLanguage]?[key] ?? key;
  }
}
