// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visual_impaired_assistive_app/main.dart';
import 'package:visual_impaired_assistive_app/providers/auth_provider.dart';
import 'package:visual_impaired_assistive_app/providers/location_provider.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app title is present
    expect(find.text('Visual Impaired Assistant'), findsOneWidget);
  });
}
