import 'package:js/js.dart';

@JS()
@staticInterop
class FirebaseUtils {
  external factory FirebaseUtils();
}

extension FirebaseUtilsExtension on FirebaseUtils {
  @JS()
  external dynamic getFirebase();

  @JS()
  external dynamic getAuth();

  @JS()
  external dynamic getFirestore();

  @JS()
  external dynamic getStorage();
}

// Helper functions to get Firebase services
dynamic getFirebaseInstance() {
  return FirebaseUtils().getFirebase();
}

dynamic getAuthInstance() {
  return FirebaseUtils().getAuth();
}

dynamic getFirestoreInstance() {
  return FirebaseUtils().getFirestore();
}

dynamic getStorageInstance() {
  return FirebaseUtils().getStorage();
}

// Helper functions for converting between Dart and JS objects
dynamic jsify(dynamic object) {
  return object;
}

dynamic dartify(dynamic object) {
  return object;
}
