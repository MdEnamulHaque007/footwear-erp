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
