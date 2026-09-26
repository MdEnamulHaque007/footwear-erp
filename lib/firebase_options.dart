/// ============================================================================
/// ফাইল: lib/firebase_options.dart
/// স্তর: Application | মডিউল: ERP Common
/// উদ্দেশ্য: Firebase Options component-এর নির্ধারিত application responsibility বাস্তবায়ন করে।
/// প্রধান অংশ: DefaultFirebaseOptions
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
