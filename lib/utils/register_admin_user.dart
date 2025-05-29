import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

// Do NOT store passwords in plaintext in code. Use environment variables or secure storage for production.
const adminPassword =
    String.fromEnvironment('ADMIN_PASSWORD', defaultValue: 'AdminPassword123!');

Future<void> registerAdminUser() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const adminEmail = 'admin@example.com';
  // Use the password from environment variable or fallback
  final adminPasswordValue = adminPassword;

  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: adminEmail,
      password: adminPasswordValue,
    );
    final uid = userCredential.user?.uid;
    print('Admin user created with UID: $uid');

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': adminEmail,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      // Add any additional admin fields here if needed
    });

    print('Admin user added to Firestore with role "admin".');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('Admin user already exists.');
    } else {
      print('Failed to create admin user: ${e.message}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}
