/// ============================================================================
/// ফাইল: lib/core/utils/validators/auth_validator.dart
/// স্তর: Core | মডিউল: Authentication
/// উদ্দেশ্য: Auth Validator সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: AuthValidator
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class AuthValidator {
  static String? validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateName(String value) {
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateConfirmPassword(String password, String confirmation) {
    if (password != confirmation) return 'Passwords do not match';
    return null;
  }
}
