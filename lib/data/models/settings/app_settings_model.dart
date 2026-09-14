import '../../../domain/entities/settings/app_settings_entity.dart';

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    super.themeMode,
    super.languageCode,
    super.fontSize,
    super.emailNotifications,
    super.pushNotifications,
    super.inAppNotifications,
    super.soundAlerts,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      AppSettingsModel(
        themeMode: _string(json['themeMode'], fallback: 'system'),
        languageCode: _string(json['languageCode'], fallback: 'en'),
        fontSize: _string(json['fontSize'], fallback: 'medium'),
        emailNotifications: _bool(json['emailNotifications']),
        pushNotifications: _bool(json['pushNotifications']),
        inAppNotifications: _bool(json['inAppNotifications']),
        soundAlerts: _bool(json['soundAlerts']),
      );

  @override
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'languageCode': languageCode,
    'fontSize': fontSize,
    'emailNotifications': emailNotifications,
    'pushNotifications': pushNotifications,
    'inAppNotifications': inAppNotifications,
    'soundAlerts': soundAlerts,
  };

  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) =>
      AppSettingsModel(
        themeMode: entity.themeMode,
        languageCode: entity.languageCode,
        fontSize: entity.fontSize,
        emailNotifications: entity.emailNotifications,
        pushNotifications: entity.pushNotifications,
        inAppNotifications: entity.inAppNotifications,
        soundAlerts: entity.soundAlerts,
      );

  AppSettingsEntity toEntity() => AppSettingsEntity(
    themeMode: themeMode,
    languageCode: languageCode,
    fontSize: fontSize,
    emailNotifications: emailNotifications,
    pushNotifications: pushNotifications,
    inAppNotifications: inAppNotifications,
    soundAlerts: soundAlerts,
  );

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static bool _bool(dynamic value, {bool fallback = true}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return fallback;
  }
}
