import 'package:equatable/equatable.dart';

class AppSettingsEntity extends Equatable {
  const AppSettingsEntity({
    this.themeMode = 'system',
    this.languageCode = 'en',
    this.fontSize = 'medium',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.inAppNotifications = true,
    this.soundAlerts = true,
  });

  final String themeMode;
  final String languageCode;
  final String fontSize;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool inAppNotifications;
  final bool soundAlerts;

  factory AppSettingsEntity.defaults() => const AppSettingsEntity();

  AppSettingsEntity copyWith({
    String? themeMode,
    String? languageCode,
    String? fontSize,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? inAppNotifications,
    bool? soundAlerts,
  }) => AppSettingsEntity(
    themeMode: themeMode ?? this.themeMode,
    languageCode: languageCode ?? this.languageCode,
    fontSize: fontSize ?? this.fontSize,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    inAppNotifications: inAppNotifications ?? this.inAppNotifications,
    soundAlerts: soundAlerts ?? this.soundAlerts,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'languageCode': languageCode,
    'fontSize': fontSize,
    'emailNotifications': emailNotifications,
    'pushNotifications': pushNotifications,
    'inAppNotifications': inAppNotifications,
    'soundAlerts': soundAlerts,
  };

  factory AppSettingsEntity.fromJson(Map<String, dynamic> json) =>
      AppSettingsEntity(
        themeMode: json['themeMode'] as String? ?? 'system',
        languageCode: json['languageCode'] as String? ?? 'en',
        fontSize: json['fontSize'] as String? ?? 'medium',
        emailNotifications: json['emailNotifications'] as bool? ?? true,
        pushNotifications: json['pushNotifications'] as bool? ?? true,
        inAppNotifications: json['inAppNotifications'] as bool? ?? true,
        soundAlerts: json['soundAlerts'] as bool? ?? true,
      );

  @override
  List<Object> get props => [
    themeMode,
    languageCode,
    fontSize,
    emailNotifications,
    pushNotifications,
    inAppNotifications,
    soundAlerts,
  ];
}
