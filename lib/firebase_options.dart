import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAmJ8hPkm-iSL5XrI0VjMuM5isNJNnHjKg',
    appId: '1:1095501567322:web:cf4939e5fe013a58ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    authDomain: 'visual-impaired-assistant.firebaseapp.com',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    measurementId: 'G-MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmJ8hPkm-iSL5XrI0VjMuM5isNJNnHjKg',
    appId: '1:1095501567322:android:cf4939e5fe013a58ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAmJ8hPkm-iSL5XrI0VjMuM5isNJNnHjKg',
    appId: '1:1095501567322:ios:cf4939e5fe013a58ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    iosClientId: '1095501567322-ios.apps.googleusercontent.com',
    iosBundleId: 'com.visualimpaired.assistant',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAmJ8hPkm-iSL5XrI0VjMuM5isNJNnHjKg',
    appId: '1:1095501567322:macos:cf4939e5fe013a58ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    iosClientId: '1095501567322-ios.apps.googleusercontent.com',
    iosBundleId: 'com.visualimpaired.assistant',
  );
}
