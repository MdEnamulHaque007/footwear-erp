/// ============================================================================
/// ফাইল: lib/core/utils/validators/quantity_validator.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Quantity Validator সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: QuantityValidator
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class QuantityValidator {
  static bool isValidQuantity(int quantity) => quantity > 0;

  static bool isWithinLimit(int quantity, int limit) => quantity <= limit;

  static String? validateCuttingQuantity(
    int cuttingQuantity,
    int availablePOQuantity,
  ) {
    if (!isValidQuantity(cuttingQuantity)) {
      return 'Quantity must be greater than 0';
    }
    // Cutting is the only soft-limit stage. It may exceed the remaining PO
    // balance; callers use [cuttingExcess] to report the over-cut quantity.
    return null;
  }

  static int cuttingExcess(int cuttingQuantity, int availablePOQuantity) {
    final excess = cuttingQuantity - availablePOQuantity;
    return excess > 0 ? excess : 0;
  }
}
