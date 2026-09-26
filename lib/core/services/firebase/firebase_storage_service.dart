/// ============================================================================
/// ফাইল: lib/core/services/firebase/firebase_storage_service.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Firebase Storage Service সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: FirebaseStorageService
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;
  FirebaseStorage get instance => _storage;
}
