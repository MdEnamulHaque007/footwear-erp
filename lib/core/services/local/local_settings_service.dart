import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/settings/app_settings_entity.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';

class LocalSettingsService {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLanguageCode = 'app_language_code';
  static const String _keyFontSize = 'app_font_size';
  static const String _keyEmailNotifications = 'app_email_notifications';
  static const String _keyPushNotifications = 'app_push_notifications';
  static const String _keyInAppNotifications = 'app_in_app_notifications';
  static const String _keySoundAlerts = 'app_sound_alerts';
  static const String _keyBusinessSettings = 'business_settings';

  Future<void> saveAppSettings(AppSettingsEntity entity) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_keyThemeMode, entity.themeMode),
      preferences.setString(_keyLanguageCode, entity.languageCode),
      preferences.setString(_keyFontSize, entity.fontSize),
      preferences.setBool(_keyEmailNotifications, entity.emailNotifications),
      preferences.setBool(_keyPushNotifications, entity.pushNotifications),
      preferences.setBool(_keyInAppNotifications, entity.inAppNotifications),
      preferences.setBool(_keySoundAlerts, entity.soundAlerts),
    ]);
  }

  Future<AppSettingsEntity?> getAppSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final hasAnyValue =
        preferences.containsKey(_keyThemeMode) ||
        preferences.containsKey(_keyLanguageCode) ||
        preferences.containsKey(_keyFontSize) ||
        preferences.containsKey(_keyEmailNotifications) ||
        preferences.containsKey(_keyPushNotifications) ||
        preferences.containsKey(_keyInAppNotifications) ||
        preferences.containsKey(_keySoundAlerts);
    if (!hasAnyValue) return null;

    return AppSettingsEntity(
      themeMode: preferences.getString(_keyThemeMode) ?? 'system',
      languageCode: preferences.getString(_keyLanguageCode) ?? 'en',
      fontSize: preferences.getString(_keyFontSize) ?? 'medium',
      emailNotifications: preferences.getBool(_keyEmailNotifications) ?? true,
      pushNotifications: preferences.getBool(_keyPushNotifications) ?? true,
      inAppNotifications: preferences.getBool(_keyInAppNotifications) ?? true,
      soundAlerts: preferences.getBool(_keySoundAlerts) ?? true,
    );
  }

  Future<void> clearAppSettings() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_keyThemeMode),
      preferences.remove(_keyLanguageCode),
      preferences.remove(_keyFontSize),
      preferences.remove(_keyEmailNotifications),
      preferences.remove(_keyPushNotifications),
      preferences.remove(_keyInAppNotifications),
      preferences.remove(_keySoundAlerts),
    ]);
  }

  /// Used by the debug-only authentication bypass, where no Firebase user is
  /// present to satisfy the production Firestore security rules.
  Future<void> saveBusinessSettings(BusinessSettingsEntity entity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _keyBusinessSettings,
      jsonEncode(entity.toJson()),
    );
  }

  Future<BusinessSettingsEntity?> getBusinessSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_keyBusinessSettings);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return BusinessSettingsEntity.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException {
      return null;
    }
  }
}
