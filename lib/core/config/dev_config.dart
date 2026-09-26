/// ============================================================================
/// ফাইল: lib/core/config/dev_config.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Dev Config সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: DevConfig
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
/// Development configuration for Firebase emulators and debug flags.
///
/// This file controls whether the app connects to local Firebase emulators
/// instead of production. Only enable in development.
class DevConfig {
  /// Set to true to use local Firebase Auth + Firestore emulators.
  static const bool useFirebaseEmulator = false;

  /// Host for the emulator (usually localhost or 127.0.0.1).
  static const String emulatorHost = 'localhost';

  /// Auth emulator port (default 9099).
  static const int authEmulatorPort = 9099;

  /// Firestore emulator port (default 8080).
  static const int firestoreEmulatorPort = 8080;
}
