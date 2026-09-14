import '../../../domain/entities/settings/business_settings_entity.dart';

class BusinessSettingsModel extends BusinessSettingsEntity {
  const BusinessSettingsModel({
    super.companyName,
    super.companyAddress,
    super.companyPhone,
    super.companyEmail,
    super.companyLogo,
    super.factoryList,
    super.projectList,
    super.brandList,
    super.articleList,
    super.colorList,
    super.currency,
    super.voucherPrefixes,
    super.unit,
  });

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) =>
      BusinessSettingsModel(
        companyName: _string(
          json['companyName'],
          fallback: 'IALT Footwear Ltd.',
        ),
        companyAddress: _string(json['companyAddress']),
        companyPhone: _string(json['companyPhone']),
        companyEmail: _string(json['companyEmail']),
        companyLogo: _nullableString(json['companyLogo']),
        factoryList: _listString(json['factoryList']),
        projectList: _listString(json['projectList']),
        brandList: _listString(json['brandList']),
        articleList: _listString(json['articleList']),
        colorList: _listString(json['colorList']),
        currency: _string(json['currency'], fallback: 'USD'),
        voucherPrefixes: _mapString(json['voucherPrefixes']),
        unit: _string(json['unit'], fallback: 'pair'),
      );

  @override
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

  factory BusinessSettingsModel.fromEntity(BusinessSettingsEntity entity) =>
      BusinessSettingsModel(
        companyName: entity.companyName,
        companyAddress: entity.companyAddress,
        companyPhone: entity.companyPhone,
        companyEmail: entity.companyEmail,
        companyLogo: entity.companyLogo,
        factoryList: entity.factoryList,
        projectList: entity.projectList,
        brandList: entity.brandList,
        articleList: entity.articleList,
        colorList: entity.colorList,
        currency: entity.currency,
        voucherPrefixes: entity.voucherPrefixes,
        unit: entity.unit,
      );

  BusinessSettingsEntity toEntity() => BusinessSettingsEntity(
    companyName: companyName,
    companyAddress: companyAddress,
    companyPhone: companyPhone,
    companyEmail: companyEmail,
    companyLogo: companyLogo,
    factoryList: factoryList,
    projectList: projectList,
    brandList: brandList,
    articleList: articleList,
    colorList: colorList,
    currency: currency,
    voucherPrefixes: voucherPrefixes,
    unit: unit,
  );

  static String _string(dynamic value, {String fallback = ''}) => value == null
      ? fallback
      : value.toString();

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final string = value.toString().trim();
    return string.isEmpty ? null : string;
  }

  static List<String> _listString(dynamic value) {
    if (value is! List) return [];
    return value.where((item) => item != null).map(_string).toList();
  }

  static Map<String, String> _mapString(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(_string(key), _string(item)),
    );
  }
}
