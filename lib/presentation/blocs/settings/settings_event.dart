/// ============================================================================
/// ফাইল: lib/presentation/blocs/settings/settings_event.dart
/// স্তর: Presentation BLoC | মডিউল: Settings
/// উদ্দেশ্য: Settings screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: SettingsEvent, LoadAppSettings, LoadBusinessSettings, SaveAppSettings, UpdateTheme, UpdateLanguage, UpdateFontSize, UpdateNotifications, SaveBusinessSettings, UpdateFactoryList
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import '../../../domain/entities/settings/app_settings_entity.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppSettings extends SettingsEvent {
  const LoadAppSettings();
}

class LoadBusinessSettings extends SettingsEvent {
  const LoadBusinessSettings();
}

class SaveAppSettings extends SettingsEvent {
  const SaveAppSettings(this.entity);

  final AppSettingsEntity entity;

  @override
  List<Object?> get props => [entity];
}

class UpdateTheme extends SettingsEvent {
  const UpdateTheme(this.themeMode);

  final String themeMode;

  @override
  List<Object?> get props => [themeMode];
}

class UpdateLanguage extends SettingsEvent {
  const UpdateLanguage(this.languageCode);

  final String languageCode;

  @override
  List<Object?> get props => [languageCode];
}

class UpdateFontSize extends SettingsEvent {
  const UpdateFontSize(this.fontSize);

  final String fontSize;

  @override
  List<Object?> get props => [fontSize];
}

class UpdateNotifications extends SettingsEvent {
  const UpdateNotifications({
    required this.email,
    required this.push,
    required this.inApp,
    required this.sound,
  });

  final bool email;
  final bool push;
  final bool inApp;
  final bool sound;

  @override
  List<Object?> get props => [email, push, inApp, sound];
}

class SaveBusinessSettings extends SettingsEvent {
  const SaveBusinessSettings(this.entity);

  final BusinessSettingsEntity entity;

  @override
  List<Object?> get props => [entity];
}

class UpdateFactoryList extends SettingsEvent {
  const UpdateFactoryList(this.list);

  final List<String> list;

  @override
  List<Object?> get props => [list];
}

class UpdateProjectList extends SettingsEvent {
  const UpdateProjectList(this.list);

  final List<String> list;

  @override
  List<Object?> get props => [list];
}

class UpdateBrandList extends SettingsEvent {
  const UpdateBrandList(this.list);

  final List<String> list;

  @override
  List<Object?> get props => [list];
}

class UpdateArticleList extends SettingsEvent {
  const UpdateArticleList(this.list);

  final List<String> list;

  @override
  List<Object?> get props => [list];
}

class UpdateColorList extends SettingsEvent {
  const UpdateColorList(this.list);

  final List<String> list;

  @override
  List<Object?> get props => [list];
}

class ResetToDefaults extends SettingsEvent {
  const ResetToDefaults();
}
