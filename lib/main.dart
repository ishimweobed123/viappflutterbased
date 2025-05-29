import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:visual_impaired_assistive_app/firebase_options.dart';
import 'package:visual_impaired_assistive_app/providers/auth_provider.dart';
import 'package:visual_impaired_assistive_app/providers/location_provider.dart';
import 'package:visual_impaired_assistive_app/providers/notification_provider.dart';
import 'package:visual_impaired_assistive_app/providers/obstacle_provider.dart';
import 'package:visual_impaired_assistive_app/providers/navigation_route_provider.dart';
import 'package:visual_impaired_assistive_app/screens/home_screen.dart';
import 'package:visual_impaired_assistive_app/screens/login_screen.dart';
import 'package:visual_impaired_assistive_app/screens/admin_dashboard_screen.dart';
import 'package:visual_impaired_assistive_app/providers/language_provider.dart';
import 'package:visual_impaired_assistive_app/providers/dashboard_provider.dart';
import 'package:visual_impaired_assistive_app/providers/session_provider.dart';
import 'package:visual_impaired_assistive_app/providers/danger_zone_provider.dart';
import 'package:visual_impaired_assistive_app/screens/danger_zones_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ObstacleProvider()),
        ChangeNotifierProvider(create: (_) => NavigationRouteProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => DangerZoneProvider()),
      ],
      child: MaterialApp(
        title: 'Visual Impaired Assistant',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/danger-zones': (context) => const DangerZonesScreen(),
        },
      ),
    );
  }
}
