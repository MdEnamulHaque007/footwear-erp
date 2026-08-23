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
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCVGZhvhaQ1fjjXz1v0sNZAt07mGyFePQM',
    appId: '1:214502080988:web:17a61f1c554b5b75900f19',
    messagingSenderId: '214502080988',
    projectId: 'footwear-9d10e',
    authDomain: 'footwear-9d10e.firebaseapp.com',
    storageBucket: 'footwear-9d10e.firebasestorage.app',
  );
}
