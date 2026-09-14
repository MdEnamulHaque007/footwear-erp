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
