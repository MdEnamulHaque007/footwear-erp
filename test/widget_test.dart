/// ============================================================================
/// ফাইল: test/widget_test.dart
/// স্তর: Test | মডিউল: ERP Common
/// উদ্দেশ্য: Widget Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/core/utils/validators/auth_validator.dart';

void main() {
  test('auth validation accepts valid input', () {
    expect(AuthValidator.validateEmail('user@example.com'), isNull);
    expect(AuthValidator.validatePassword('secret1'), isNull);
    expect(AuthValidator.validateName('User'), isNull);
    expect(AuthValidator.validateConfirmPassword('secret1', 'secret1'), isNull);
  });
}
