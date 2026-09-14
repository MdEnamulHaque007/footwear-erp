import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/settings/app_settings_entity.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';
import '../../../domain/usecases/settings/get_app_settings_usecase.dart';
import '../../../domain/usecases/settings/get_business_settings_usecase.dart';
import '../../../domain/usecases/settings/save_app_settings_usecase.dart';
import '../../../domain/usecases/settings/save_business_settings_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required GetAppSettingsUseCase getAppSettings,
    required SaveAppSettingsUseCase saveAppSettings,
    required GetBusinessSettingsUseCase getBusinessSettings,
    required SaveBusinessSettingsUseCase saveBusinessSettings,
  }) : _getAppSettings = getAppSettings,
       _saveAppSettings = saveAppSettings,
       _getBusinessSettings = getBusinessSettings,
       _saveBusinessSettings = saveBusinessSettings,
       super(const SettingsInitial()) {
    on<LoadAppSettings>(_onLoadAppSettings);
    on<LoadBusinessSettings>(_onLoadBusinessSettings);
    on<SaveAppSettings>(_onSaveAppSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<SaveBusinessSettings>(_onSaveBusinessSettings);
    on<UpdateFactoryList>(_onUpdateFactoryList);
    on<UpdateProjectList>(_onUpdateProjectList);
    on<UpdateBrandList>(_onUpdateBrandList);
    on<UpdateArticleList>(_onUpdateArticleList);
    on<UpdateColorList>(_onUpdateColorList);
    on<ResetToDefaults>(_onResetToDefaults);
  }

  final GetAppSettingsUseCase _getAppSettings;
  final SaveAppSettingsUseCase _saveAppSettings;
  final GetBusinessSettingsUseCase _getBusinessSettings;
  final SaveBusinessSettingsUseCase _saveBusinessSettings;

  AppSettingsEntity _appSettings = AppSettingsEntity.defaults();
  BusinessSettingsEntity _businessSettings = BusinessSettingsEntity.defaults();

  /// The latest app-level preferences, kept independently from transient
  /// business-settings states so the application shell can apply them safely.
  AppSettingsEntity get currentAppSettings => _appSettings;

  BusinessSettingsEntity get currentBusinessSettings => _businessSettings;

  Future<void> _onLoadAppSettings(
    LoadAppSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final result = await _getAppSettings();
      if (emit.isDone) return;
      result.fold((error) => emit(SettingsError(error)), (entity) {
        _appSettings = entity;
        emit(AppSettingsLoaded(entity));
      });
    } catch (error) {
      if (!emit.isDone) {
        emit(SettingsError('Failed to load app settings: $error'));
      }
    }
  }

  Future<void> _onLoadBusinessSettings(
    LoadBusinessSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final result = await _getBusinessSettings();
      if (emit.isDone) return;
      result.fold((error) => emit(SettingsError(error)), (entity) {
        _businessSettings = entity;
        emit(BusinessSettingsLoaded(entity));
      });
    } catch (error) {
      if (!emit.isDone) {
        emit(SettingsError('Failed to load business settings: $error'));
      }
    }
  }

  Future<void> _onSaveAppSettings(
    SaveAppSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final result = await _saveAppSettings(event.entity);
      if (emit.isDone) return;
      result.fold((error) => emit(SettingsError(error)), (_) {
        _appSettings = event.entity;
        emit(const SettingsSaved('App settings saved successfully'));
        emit(AppSettingsLoaded(_appSettings));
      });
    } catch (error) {
      if (!emit.isDone) {
        emit(SettingsError('Failed to save app settings: $error'));
      }
    }
  }

  Future<void> _onUpdateTheme(UpdateTheme event, Emitter<SettingsState> emit) =>
      _saveUpdatedAppSettings(
        _appSettings.copyWith(themeMode: event.themeMode),
        'Theme updated',
        emit,
      );

  Future<void> _onUpdateLanguage(
    UpdateLanguage event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedAppSettings(
    _appSettings.copyWith(languageCode: event.languageCode),
    'Language updated',
    emit,
  );

  Future<void> _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedAppSettings(
    _appSettings.copyWith(fontSize: event.fontSize),
    'Font size updated',
    emit,
  );

  Future<void> _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedAppSettings(
    _appSettings.copyWith(
      emailNotifications: event.email,
      pushNotifications: event.push,
      inAppNotifications: event.inApp,
      soundAlerts: event.sound,
    ),
    'Notifications updated',
    emit,
  );

  Future<void> _onSaveBusinessSettings(
    SaveBusinessSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final result = await _saveBusinessSettings(event.entity);
      if (emit.isDone) return;
      result.fold((error) => emit(SettingsError(error)), (_) {
        _businessSettings = event.entity;
        emit(const SettingsSaved('Business settings saved successfully'));
        emit(BusinessSettingsLoaded(_businessSettings));
      });
    } catch (error) {
      if (!emit.isDone) {
        emit(SettingsError('Failed to save business settings: $error'));
      }
    }
  }

  Future<void> _onUpdateFactoryList(
    UpdateFactoryList event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedBusinessSettings(
    _businessSettings.copyWith(factoryList: event.list),
    'Factory list updated',
    emit,
  );

  Future<void> _onUpdateProjectList(
    UpdateProjectList event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedBusinessSettings(
    _businessSettings.copyWith(projectList: event.list),
    'Project list updated',
    emit,
  );

  Future<void> _onUpdateBrandList(
    UpdateBrandList event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedBusinessSettings(
    _businessSettings.copyWith(brandList: event.list),
    'Brand list updated',
    emit,
  );

  Future<void> _onUpdateArticleList(
    UpdateArticleList event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedBusinessSettings(
    _businessSettings.copyWith(articleList: event.list),
    'Article list updated',
    emit,
  );

  Future<void> _onUpdateColorList(
    UpdateColorList event,
    Emitter<SettingsState> emit,
  ) => _saveUpdatedBusinessSettings(
    _businessSettings.copyWith(colorList: event.list),
    'Color list updated',
    emit,
  );

  Future<void> _onResetToDefaults(
    ResetToDefaults event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final appDefaults = AppSettingsEntity.defaults();
      final businessDefaults = BusinessSettingsEntity.defaults();
      final appResult = await _saveAppSettings(appDefaults);
      if (emit.isDone) return;
      final appError = appResult.fold<String?>((error) => error, (_) => null);
      if (appError != null) {
        emit(SettingsError(appError));
        return;
      }
      final businessResult = await _saveBusinessSettings(businessDefaults);
      if (emit.isDone) return;
      businessResult.fold((error) => emit(SettingsError(error)), (_) {
        _appSettings = appDefaults;
        _businessSettings = businessDefaults;
        emit(const SettingsReset());
        emit(const SettingsSaved('Reset to defaults'));
      });
    } catch (error) {
      if (!emit.isDone) emit(SettingsError('Failed to reset settings: $error'));
    }
  }

  Future<void> _saveUpdatedAppSettings(
    AppSettingsEntity entity,
    String message,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final result = await _saveAppSettings(entity);
      if (emit.isDone) return;
      result.fold((error) => emit(SettingsError(error)), (_) {
        _appSettings = entity;
        emit(SettingsSaved(message));
        emit(AppSettingsLoaded(entity));
      });
    } catch (error) {
      if (!emit.isDone) {
        emit(SettingsError('Failed to update settings: $error'));
      }
    }
  }

  Future<void> _saveUpdatedBusinessSettings(
    BusinessSettingsEntity entity,
    String message,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final result = await _saveBusinessSettings(entity);
      if (emit.isDone) return;
      result.fold((error) => emit(SettingsError(error)), (_) {
        _businessSettings = entity;
        emit(SettingsSaved(message));
        emit(BusinessSettingsLoaded(entity));
      });
    } catch (error) {
      if (!emit.isDone) {
        emit(SettingsError('Failed to update settings: $error'));
      }
    }
  }
}
