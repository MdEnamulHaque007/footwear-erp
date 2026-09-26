/// ============================================================================
/// ফাইল: lib/presentation/blocs/settings/settings_state.dart
/// স্তর: Presentation BLoC | মডিউল: Settings
/// উদ্দেশ্য: Settings screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: SettingsState, SettingsInitial, SettingsLoading, AppSettingsLoaded, BusinessSettingsLoaded, BothSettingsLoaded, SettingsSaved, SettingsError, SettingsReset
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import '../../../domain/entities/settings/app_settings_entity.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class AppSettingsLoaded extends SettingsState {
  const AppSettingsLoaded(this.entity);

  final AppSettingsEntity entity;

  @override
  List<Object?> get props => [entity];
}

class BusinessSettingsLoaded extends SettingsState {
  const BusinessSettingsLoaded(this.entity);

  final BusinessSettingsEntity entity;

  @override
  List<Object?> get props => [entity];
}

class BothSettingsLoaded extends SettingsState {
  const BothSettingsLoaded({
    required this.appSettings,
    required this.businessSettings,
  });

  final AppSettingsEntity appSettings;
  final BusinessSettingsEntity businessSettings;

  @override
  List<Object?> get props => [appSettings, businessSettings];
}

class SettingsSaved extends SettingsState {
  const SettingsSaved(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SettingsError extends SettingsState {
  const SettingsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SettingsReset extends SettingsState {
  const SettingsReset();
}
