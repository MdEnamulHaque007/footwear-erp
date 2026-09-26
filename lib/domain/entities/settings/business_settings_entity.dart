/// ============================================================================
/// ফাইল: lib/domain/entities/settings/business_settings_entity.dart
/// স্তর: Domain Entity | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: BusinessSettingsEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

class BusinessSettingsEntity extends Equatable {
  const BusinessSettingsEntity({
    this.companyName = 'IALT Footwear Ltd.',
    this.companyAddress = '',
    this.companyPhone = '',
    this.companyEmail = '',
    this.companyLogo,
    this.factoryList = const ['Factory A', 'Factory B'],
    this.projectList = const ['UPTOP'],
    this.brandList = const [],
    this.articleList = const [],
    this.colorList = const [],
    this.currency = 'USD',
    this.voucherPrefixes = const {
      'cutting': 'CUT',
      'sewing': 'SEW',
      'production': 'PRO',
      'issue': 'ISS',
      'export': 'EXP',
    },
    this.unit = 'pair',
  });

  static const _unset = Object();

  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String? companyLogo;
  final List<String> factoryList;
  final List<String> projectList;
  final List<String> brandList;
  final List<String> articleList;
  final List<String> colorList;
  final String currency;
  final Map<String, String> voucherPrefixes;
  final String unit;

  factory BusinessSettingsEntity.defaults() => const BusinessSettingsEntity();

  BusinessSettingsEntity copyWith({
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    Object? companyLogo = _unset,
    List<String>? factoryList,
    List<String>? projectList,
    List<String>? brandList,
    List<String>? articleList,
    List<String>? colorList,
    String? currency,
    Map<String, String>? voucherPrefixes,
    String? unit,
  }) => BusinessSettingsEntity(
    companyName: companyName ?? this.companyName,
    companyAddress: companyAddress ?? this.companyAddress,
    companyPhone: companyPhone ?? this.companyPhone,
    companyEmail: companyEmail ?? this.companyEmail,
    companyLogo: identical(companyLogo, _unset)
        ? this.companyLogo
        : companyLogo as String?,
    factoryList: factoryList ?? this.factoryList,
    projectList: projectList ?? this.projectList,
    brandList: brandList ?? this.brandList,
    articleList: articleList ?? this.articleList,
    colorList: colorList ?? this.colorList,
    currency: currency ?? this.currency,
    voucherPrefixes: voucherPrefixes ?? this.voucherPrefixes,
    unit: unit ?? this.unit,
  );

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'companyAddress': companyAddress,
    'companyPhone': companyPhone,
    'companyEmail': companyEmail,
    'companyLogo': companyLogo,
    'factoryList': factoryList,
    'projectList': projectList,
    'brandList': brandList,
    'articleList': articleList,
    'colorList': colorList,
    'currency': currency,
    'voucherPrefixes': voucherPrefixes,
    'unit': unit,
  };

  factory BusinessSettingsEntity.fromJson(Map<String, dynamic> json) =>
      BusinessSettingsEntity(
        companyName: _string(
          json['companyName'],
          fallback: 'IALT Footwear Ltd.',
        ),
        companyAddress: _string(json['companyAddress']),
        companyPhone: _string(json['companyPhone']),
        companyEmail: _string(json['companyEmail']),
        companyLogo: json['companyLogo'] == null
            ? null
            : _string(json['companyLogo']),
        factoryList: _listString(
          json['factoryList'],
          fallback: const ['Factory A', 'Factory B'],
        ),
        projectList: _listString(
          json['projectList'],
          fallback: const ['UPTOP'],
        ),
        brandList: _listString(json['brandList']),
        articleList: _listString(json['articleList']),
        colorList: _listString(json['colorList']),
        currency: _string(json['currency'], fallback: 'USD'),
        voucherPrefixes: _mapString(
          json['voucherPrefixes'],
          fallback: const {
            'cutting': 'CUT',
            'sewing': 'SEW',
            'production': 'PRO',
            'issue': 'ISS',
            'export': 'EXP',
          },
        ),
        unit: _string(json['unit'], fallback: 'pair'),
      );

  static String _string(Object? value, {String fallback = ''}) => value == null
      ? fallback
      : value is String
      ? value
      : value.toString();

  static List<String> _listString(
    Object? value, {
    List<String> fallback = const [],
  }) {
    if (value is! Iterable) return List<String>.from(fallback);
    return value.map((item) => _string(item)).toList();
  }

  static Map<String, String> _mapString(
    Object? value, {
    Map<String, String> fallback = const {},
  }) {
    if (value is! Map) return Map<String, String>.from(fallback);
    return value.map((key, item) => MapEntry(_string(key), _string(item)));
  }

  @override
  List<Object?> get props => [
    companyName,
    companyAddress,
    companyPhone,
    companyEmail,
    companyLogo,
    factoryList,
    projectList,
    brandList,
    articleList,
    colorList,
    currency,
    voucherPrefixes,
    unit,
  ];
}
