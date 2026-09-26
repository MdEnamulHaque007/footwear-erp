/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/criteria_option_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: CriteriaType, CriteriaOption, ValueType, ValueTypeExtension
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
enum CriteriaType { date, category, identifier }

class CriteriaOption {
  const CriteriaOption({
    required this.label,
    required this.field,
    required this.type,
    required this.icon,
  });

  final String label;
  final String field;
  final CriteriaType type;
  final String icon;

  static const List<CriteriaOption> all = [
    CriteriaOption(label: 'Date (Month)', field: 'date', type: CriteriaType.date, icon: '📅'),
    CriteriaOption(label: 'Department', field: 'department', type: CriteriaType.category, icon: '🏭'),
    CriteriaOption(label: 'Factory', field: 'factoryName', type: CriteriaType.category, icon: '🏢'),
    CriteriaOption(label: 'PO No', field: 'poNo', type: CriteriaType.identifier, icon: '📋'),
    CriteriaOption(label: 'Article', field: 'article', type: CriteriaType.identifier, icon: '📦'),
    CriteriaOption(label: 'Color', field: 'color', type: CriteriaType.category, icon: '🎨'),
    CriteriaOption(label: 'Tag No', field: 'tagNo', type: CriteriaType.identifier, icon: '🏷️'),
    CriteriaOption(label: 'Company', field: 'company', type: CriteriaType.category, icon: '🏛️'),
    CriteriaOption(label: 'Project', field: 'project', type: CriteriaType.category, icon: '📁'),
    CriteriaOption(label: 'Entry Person', field: 'entryPerson', type: CriteriaType.category, icon: '👤'),
  ];

  static CriteriaOption fromField(String field) => all.firstWhere(
    (option) => option.field == field,
    orElse: () => all.first,
  );
}

enum ValueType { quantity, value }

extension ValueTypeExtension on ValueType {
  String get label => switch (this) {
    ValueType.quantity => '📊 Quantity',
    ValueType.value => '💰 Value',
  };
}
