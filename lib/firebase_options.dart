import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCVGZhvhaQ1fjjXz1v0sNZAt07mGyFePQM",
    authDomain: "footwear-9d10e.firebaseapp.com",
    projectId: "footwear-9d10e",
    storageBucket: "footwear-9d10e.firebasestorage.app",
    messagingSenderId: "214502080988",
    appId: "1:214502080988:web:17a61f1c554b5b75900f19",
  );
}
