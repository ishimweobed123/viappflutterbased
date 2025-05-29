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
        return windows;
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
    apiKey: 'AIzaSyD_y1H9iwi5lOeqQkIjU9jiObBZlXF19Gk',
    appId: '1:1095501567322:web:9d2fe23887220f46ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    authDomain: 'visual-impaired-assistant.firebaseapp.com',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    measurementId: 'G-PJEEYK3JHW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmJ8hPkm-iSL5XrI0VjMuM5isNJNnHjKg',
    appId: '1:1095501567322:android:1fb857ab716ff719ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDMIkzrjnhJQYxXZ-WVMZCtNhCHU29zfqY',
    appId: '1:1095501567322:ios:444d5bd664b68135ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    iosBundleId: 'com.example.visualImpairedAssistiveApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDMIkzrjnhJQYxXZ-WVMZCtNhCHU29zfqY',
    appId: '1:1095501567322:ios:444d5bd664b68135ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    iosBundleId: 'com.example.visualImpairedAssistiveApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD_y1H9iwi5lOeqQkIjU9jiObBZlXF19Gk',
    appId: '1:1095501567322:web:e0f775e230c40d96ab0f63',
    messagingSenderId: '1095501567322',
    projectId: 'visual-impaired-assistant',
    authDomain: 'visual-impaired-assistant.firebaseapp.com',
    storageBucket: 'visual-impaired-assistant.firebasestorage.app',
    measurementId: 'G-9K23D5V851',
  );

}