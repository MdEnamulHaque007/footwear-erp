/// ===========================================================================
/// বাংলা ডকুমেন্টেশন কমেন্ট — বিস্তারিত বোঝার জন্য যোগ করা হয়েছে
/// ===========================================================================
/// Core লেয়ারের ফাইল (কনস্ট্যান্ট, থিম, ইউটিলিটি, সার্ভিস)। ফাইল: core/config/dev_config.dart
///
/// প্রজেক্ট  : Footwear ERP System (জুতার উৎপাদন ব্যবস্থাপনা সফটওয়্যার)
/// আর্কিটেকচার: Clean Architecture (Domain → Data → Presentation)
/// টেক স্ট্যাক: Flutter + Firebase (Auth/Firestore/Storage) + BLoC + GetIt + GoRouter
/// নোট       : কোনো কোড লজিক পরিবর্তন করা হয়নি, শুধু কমেন্ট যোগ করা হয়েছে।
/// ===========================================================================

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
